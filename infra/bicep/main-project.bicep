// --------------------------------------------------------------------------------------------------------------
// Main bicep file that a single AI Foundry Project inside an existing AI Foundry
// --------------------------------------------------------------------------------------------------------------
// Requirements:
//   You must have an existing AI Foundry
//   You must have an existing VNET
// --------------------------------------------------------------------------------------------------------------

targetScope = 'subscription'

@description('Resource group where AIF Project Connected Resources live')
param projectResourceGroupName string
@description('Unique project number to create')
@minValue(1)
param projectNumber int
@description('Project Name')
param projectName string = ''

@description('Existing AI Landing Zone Root Application Name that this is based on')
param existingAiCentralAppName string = ''
@description('Existing AI Landing Zone resource group')
param existingAiCentralResourceGroupName string

@description('The environment code (i.e. dev, qa, prod)')
param environmentName string = ''

@description('Primary location for all resources')
param location string

// --------------------------------------------------------------------------------------------------------------
// Personal info
// --------------------------------------------------------------------------------------------------------------
@description('My IP address for network access')
param myIpAddress string = ''
@description('Id of the user executing the deployment')
param principalId string = ''

// --------------------------------------------------------------------------------------------------------------
// Other deployment switches
// --------------------------------------------------------------------------------------------------------------
@description('Should resources be created with public access?')
param publicAccessEnabled bool = false
@description('Set this if you want to append all the resource names with a unique token')
param appendResourceTokens bool = false
@description('Create DNS Zones?')
param createDnsZones bool = true

// --------------------------------------------------------------------------------------------------------------
// Virtual machine jumpbox
// --------------------------------------------------------------------------------------------------------------
@description('Admin username for the VM (optional - only deploy VM if provided)')
param admin_username string?
@secure()
@description('Admin password for the VM (optional - only deploy VM if provided)')
param admin_password string?
@description('VM name (optional - will use generated name if not provided)')
param vm_name string?

@description('Global Region where the resources will be deployed, e.g. AM (America), EM (EMEA), AP (APAC), CH (China)')
//@allowed(['AM', 'EM', 'AP', 'CH', 'NAA'])
param regionCode string = 'NAA'

@description('Instance number for the application, e.g. 001, 002, etc. This is used to differentiate multiple instances of the same application in the same environment.')
param instanceNumber string = '001' // used to differentiate multiple instances of the same application in the same environment

// --------------------------------------------------------------------------------------------------------------
// VNET Parameters
// --------------------------------------------------------------------------------------------------------------
@description('Existing VNET name (optional - will use generated name if not provided)')
param existingVnetName string = ''
@description('Existing VNET Subnet name (optional - will use generated name if not provided)')
param subnetPeName string = ''

// --------------------------------------------------------------------------------------------------------------
// A variable masquerading as a parameter to allow for dynamic value assignment in Bicep
// --------------------------------------------------------------------------------------------------------------
param runDateTime string = utcNow()

// --------------------------------------------------------------------------------------------------------------
// Additional Tags that may be included or not
// --------------------------------------------------------------------------------------------------------------
param businessOwnerTag string = 'UNKNOWN'
param requestorNameTag string = 'UNKNOWN'
param primarySupportProviderTag string = 'UNKNOWN'
param applicationOwnerTag string = 'UNKNOWN'
param createdByTag string = 'UNKNOWN'
param costCenterTag string = 'UNKNOWN'
param ltiServiceClassTag string = 'UNKNOWN'
param requestNumberTag string = 'UNKNOWN'

// --------------------------------------------------------------------------------------------------------------
// -- Variables -------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
var resourceToken = toLower(uniqueString(subscription().id, location, projectResourceGroupName))
var rootApplication = existingAiCentralAppName != '' ? existingAiCentralAppName : projectName
var deploymentSuffix = '-${resourceToken}'

var tags = {
  'creation-date': take(runDateTime, 8)
  'environment-name': environmentName
  'requestor-name': requestorNameTag
  'application-owner': applicationOwnerTag
  'business-owner': businessOwnerTag
  'created-by': createdByTag
  'application-name': projectName
  'cost-center': costCenterTag
  'lti-service-class': ltiServiceClassTag
  'otis-region': regionCode
  'primary-support-provider': primarySupportProviderTag
  'request-number': requestNumberTag
}

var deployVirtualMachine = !empty(admin_username) && !empty(admin_password)

// --------------------------------------------------------------------------------------------------------------
// -- Resource Groups -------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
resource aiCentralResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: existingAiCentralResourceGroupName
}

resource projectResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: projectResourceGroupName
}

// --------------------------------------------------------------------------------------------------------------
// -- Generate Resource Names -----------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module resourceNames 'resourcenames.bicep' = {
  scope: projectResourceGroup
  name: 'resource-names${deploymentSuffix}'
  params: {
    applicationName: projectName
    rootApplication: rootApplication
    environmentName: environmentName
    resourceToken: appendResourceTokens ? resourceToken : ''
    regionCode: regionCode
    instance: instanceNumber
    numberOfProjects: 1
    projectNumber: projectNumber
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- VNET ------------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
var vm_name_internal = !empty(vm_name) ? vm_name : resourceNames.outputs.project_vm.vm_name
var vnet_name_internal = !empty(existingVnetName) ? existingVnetName : resourceNames.outputs.root_vnet_Name
var subnetPEName_internal = !empty(subnetPeName) ? subnetPeName : resourceNames.outputs.subnetPeName

module existingVirtualNetwork './modules/networking/vnet.bicep' = {
  name: 'vnet${deploymentSuffix}'
  scope: aiCentralResourceGroup
  params: {
    location: location
    existingVirtualNetworkName: vnet_name_internal
    existingVnetResourceGroupName: aiCentralResourceGroup.name
    newVirtualNetworkName: resourceNames.outputs.vnet_Name
    vnetAddressPrefix: null
    vnetNsgName: resourceNames.outputs.vnetNsgName
    subnetAppGwName: resourceNames.outputs.subnetAppGwName
    subnetAppGwPrefix: null
    subnetAppSeName: resourceNames.outputs.subnetAppSeName
    subnetAppSePrefix: null
    subnetPeName: subnetPEName_internal
    subnetPePrefix: null
    subnetAgentName: resourceNames.outputs.subnetAgentName
    subnetAgentPrefix: null
    subnetBastionName: resourceNames.outputs.subnetBastionName
    subnetBastionPrefix: null
    subnetJumpboxName: vm_name_internal
    subnetJumpboxPrefix: null
    subnetTrainingName: resourceNames.outputs.subnetTrainingName
    subnetTrainingPrefix: null
    subnetScoringName: resourceNames.outputs.subnetScoringName
    subnetScoringPrefix: null
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- Use an existing Identity ----------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module identity './modules/iam/identity.bicep' = {
  name: 'app-identity${deploymentSuffix}'
  scope: aiCentralResourceGroup
  params: {
    existingIdentityName: resourceNames.outputs.rootUserAssignedIdentityName
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- JumpBox ---------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module virtualMachine './modules/virtualMachine/virtualMachine.bicep' = if (deployVirtualMachine) {
  name: 'jumpboxVirtualMachineDeployment'
  scope: projectResourceGroup
  params: {
    // Required parameters
    admin_username: admin_username!
    admin_password: admin_password!
    vnet_id: existingVirtualNetwork.outputs.vnetResourceId
    vm_name: vm_name_internal
    vm_computer_name: resourceNames.outputs.project_vm.vm_name_15
    vm_nic_name: resourceNames.outputs.project_vm.vm_nic_name
    vm_pip_name: resourceNames.outputs.project_vm.vm_pip_name
    vm_os_disk_name: resourceNames.outputs.project_vm.vm_os_disk_name
    vm_nsg_name: resourceNames.outputs.project_vm.vm_nsg_name

    subnet_name: subnetPEName_internal
    // VM configuration
    vm_size: 'Standard_B2s_v2'
    os_disk_size_gb: 128
    os_type: 'Windows'
    // Location and tags
    location: location
    tags: tags
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- Cosmos Resources ------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
var uiDatabaseName = 'ChatHistory'
var sessionsDatabaseName = 'sessions'
var uiChatContainerName = 'ChatTurn'
var uiChatContainerName2 = 'ChatHistory'
var apiSessionsContainerName = 'apisessions'
var uiSessionsContainerName = 'uisessions'
var cosmosContainerArray = [
  { name: 'AgentLog', partitionKey: '/requestId' }
  { name: 'UserDocuments', partitionKey: '/userId' }
  { name: uiChatContainerName, partitionKey: '/chatId' }
  { name: uiChatContainerName2, partitionKey: '/chatId' }
]
var sessionsContainerArray = [
  { name: apiSessionsContainerName, partitionKey: '/id' }
  { name: uiSessionsContainerName, partitionKey: '/id' }
]
module cosmos './modules/database/cosmosdb.bicep' = {
  name: 'cosmos${deploymentSuffix}'
  scope: projectResourceGroup
  params: {

    accountName: resourceNames.outputs.cosmosName
    //    existingAccountName: resourceNames.outputs.cosmosName

    databaseName: uiDatabaseName
    sessionsDatabaseName: sessionsDatabaseName
    sessionContainerArray: sessionsContainerArray
    containerArray: cosmosContainerArray
    location: location
    tags: tags
    privateEndpointSubnetId: existingVirtualNetwork.outputs.subnetPeResourceID
    privateEndpointName: resourceNames.outputs.peCosmosDbName
    managedIdentityPrincipalId: identity.outputs.managedIdentityPrincipalId
    userPrincipalId: principalId
    publicNetworkAccess: publicAccessEnabled ? 'enabled' : 'disabled'
    myIpAddress: myIpAddress
    disableKeys: true
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- Search Service Resource -----------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module searchService './modules/search/search-services.bicep' = {
  name: 'search${deploymentSuffix}'
  scope: projectResourceGroup
  params: {
    disableLocalAuth: true
    location: location
    name: resourceNames.outputs.searchServiceName
    publicNetworkAccess: publicAccessEnabled ? 'enabled' : 'disabled'
    myIpAddress: myIpAddress
    privateEndpointSubnetId: existingVirtualNetwork.outputs.subnetPeResourceID
    privateEndpointName: resourceNames.outputs.peSearchServiceName
    managedIdentityId: identity.outputs.managedIdentityId
    sku: {
      name: 'basic'
    }
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- Storage Resources -----------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module storage './modules/storage/storage-account.bicep' = {
  name: 'storage${deploymentSuffix}'
  scope: projectResourceGroup
  params: {
    name: resourceNames.outputs.storageAccountName
    location: location
    tags: tags
    privateEndpointSubnetId: existingVirtualNetwork.outputs.subnetPeResourceID
    privateEndpointBlobName: resourceNames.outputs.peStorageAccountBlobName
    privateEndpointTableName: resourceNames.outputs.peStorageAccountTableName
    privateEndpointQueueName: resourceNames.outputs.peStorageAccountQueueName
    myIpAddress: myIpAddress
    containers: ['data', 'batch-input', 'batch-output']
    allowSharedKeyAccess: false
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- DNS ZONES ---------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module allDnsZones './modules/networking/all-zones.bicep' = if (createDnsZones) {
  name: 'all-dns-zones${deploymentSuffix}'
  scope: projectResourceGroup
  params: {
    tags: tags
    vnetResourceId: existingVirtualNetwork.outputs.vnetResourceId
    dnsZonesResourceGroupName: aiCentralResourceGroup.name
    aiSearchPrivateEndpointName: searchService.outputs.privateEndpointName
    storageBlobPrivateEndpointName: storage.outputs.privateEndpointBlobName
    storageQueuePrivateEndpointName: storage.outputs.privateEndpointQueueName
    storageTablePrivateEndpointName: storage.outputs.privateEndpointTableName
    cosmosPrivateEndpointName: cosmos.outputs.privateEndpointName
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- New AI Foundry Project -----------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
var aiDependecies = {
  aiSearch: {
    name: searchService.outputs.name
    resourceId: searchService.outputs.id
    resourceGroupName: searchService.outputs.resourceGroupName
    subscriptionId: searchService.outputs.subscriptionId
  }
  azureStorage: {
    name: storage.outputs.name
    resourceId: storage.outputs.id
    resourceGroupName: storage.outputs.resourceGroupName
    subscriptionId: storage.outputs.subscriptionId
  }
  cosmosDB: {
    name: cosmos.outputs.name
    resourceId: cosmos.outputs.id
    resourceGroupName: cosmos.outputs.resourceGroupName
    subscriptionId: cosmos.outputs.subscriptionId
  }
}

module aiProject1 './modules/ai/ai-project-with-caphost.bicep' = {
  scope: aiCentralResourceGroup
  name: 'aiProject${deploymentSuffix}-1'
  params: {
    foundryName: resourceNames.outputs.rootCogServiceName
    location: location
    projectNo: projectNumber
    aiDependencies: aiDependecies
  }
  dependsOn: [allDnsZones]
}
