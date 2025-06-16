// --------------------------------------------------------------------------------------------------------------
// Main bicep file that deploys a basic version of the LZ with
//   Public Endpoints, includes EVERYTHING for the application,
//   with optional parameters for existing resources.
// --------------------------------------------------------------------------------------------------------------
// You can test it with this command:
//   az deployment group create -n manual --resource-group rg_mfg-ai-lz --template-file 'main-basic.bicep' --parameters environmentName=dev applicationName=myApp
// Or with a parameter file:
//   az deployment group create -n manual --resource-group rg_mfg-ai-lz --template-file 'main-basic.bicep' --parameters main-basic.your.bicepparam
// --------------------------------------------------------------------------------------------------------------
// 	Services Needed for Chat Agent Programs:
// 		Container Apps
//    Container Registry
// 		CosmosDB
// 		Storage Account
//    Key Vault (APIM Subscription key, certificates)
// 		Azure Foundry (includes Azure Open AI)
//    APIM (may already have existing instance)
//
//  Optional Services:
//    Azure AI Search (?)
//    Bing Grounding (?)
//    Document Intelligence (?)
//
// --------------------------------------------------------------------------------------------------------------

targetScope = 'resourceGroup'

// you can supply a full application name, or you don't it will append resource tokens to a default suffix
@description('Full Application Name (supply this or use default of prefix+token)')
param applicationName string = ''
@description('If you do not supply Application Name, this prefix will be combined with a token to create a unique applicationName')
param applicationPrefix string = 'ai_doc'

@description('The environment code (i.e. dev, qa, prod)')
param environmentName string = 'dev'
@description('Environment name used by the azd command (optional)')
param azdEnvName string = ''

@description('Primary location for all resources')
param location string = resourceGroup().location

// See https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models
@description('OAI Region availability: East US, East US2, North Central US, South Central US, Sweden Central, West US, and West US3')
param openAI_deploy_location string = location

// --------------------------------------------------------------------------------------------------------------
// Personal info
// --------------------------------------------------------------------------------------------------------------
@description('My IP address for network access')
param myIpAddress string = ''
@description('Id of the user executing the deployment')
param principalId string = ''

// --------------------------------------------------------------------------------------------------------------
// Existing networks?
// --------------------------------------------------------------------------------------------------------------
@description('If you provide this is will be used instead of creating a new VNET')
param existingVnetName string = ''
@description('If you provide an existing VNET what resource group is it in?')
param existingVnetResourceGroupName string = ''
@description('If you provide this is will be used instead of creating a new VNET')
param vnetPrefix string = '10.183.4.0/22'
param subnetAppGwName string = ''
param subnetAppGwPrefix string = '10.183.5.0/24'
param subnetAppSeName string = ''
param subnetAppSePrefix string = '10.183.4.0/24'
param subnetPeName string = ''
param subnetPePrefix string = '10.183.6.0/27'
param subnetAgentName string = ''
param subnetAgentPrefix string = '10.183.6.32/27'
param subnetBastionName string = '' // This is the default for the MFG AI LZ, it can be changed to fit your needs
param subnetBastionPrefix string = '10.183.6.64/26'
param subnetJumpboxName string = '' // This is the default for the MFG AI LZ, it can be changed to fit your needs
param subnetJumpboxPrefix string = '10.183.6.128/28'
param subnetTrainingName string = ''
param subnetTrainingPrefix string = '10.183.7.0/25'
param subnetScoringName string = ''
param subnetScoringPrefix string = '10.183.7.128/25'

// --------------------------------------------------------------------------------------------------------------
// Virtual machine jumpbox
// --------------------------------------------------------------------------------------------------------------
@description('Admin username for the VM (optional - only deploy VM if provided)')
param admin_username string
@secure()
@description('Admin password for the VM (optional - only deploy VM if provided)')
param admin_password string
@description('VM name (optional - only deploy VM if provided)')
param vm_name string

// --------------------------------------------------------------------------------------------------------------
// Container App Environment
// --------------------------------------------------------------------------------------------------------------
@description('Name of the Container Apps Environment workload profile to use for the app')
param appContainerAppEnvironmentWorkloadProfileName string = 'app'
@description('Workload profiles for the Container Apps environment')
param containerAppEnvironmentWorkloadProfiles array = [
  {
    name: 'app'
    workloadProfileType: 'D4'
    minimumCount: 1
    maximumCount: 10
  }
]

// --------------------------------------------------------------------------------------------------------------
// AI Hub Parameters
// --------------------------------------------------------------------------------------------------------------
@description('Friendly name for your Azure AI resource')
param aiProjectFriendlyName string = 'Agents Project resource'
@description('Description of your Azure AI resource displayed in AI studio')
param aiProjectDescription string = 'This is an example AI Project resource for use in Azure AI Studio.'
@description('Should we deploy an AI Foundry Hub?')
param deployAIHub bool = true
@description('Should we deploy an APIM?')
param deployAPIM bool = false

// --------------------------------------------------------------------------------------------------------------
// APIM Parameters
// --------------------------------------------------------------------------------------------------------------
@description('Name of the APIM Subscription. Defaults to aiagent-subscription')
param apimSubscriptionName string = 'aiagent-subscription'
@description('Email of the APIM Publisher')
param apimPublisherEmail string = 'somebody@somewhere.com'
@description('Name of the APIM Publisher')
param adminPublisherName string = 'AI Agent Admin'

// --------------------------------------------------------------------------------------------------------------
// Existing images
// --------------------------------------------------------------------------------------------------------------
param apiImageName string = ''
param batchImageName string = ''

// --------------------------------------------------------------------------------------------------------------
// Other deployment switches
// --------------------------------------------------------------------------------------------------------------
@description('Should VNET be used in this deploy?')
param deployVNET bool = false

@description('Should resources be created with public access?')
param publicAccessEnabled bool = true
@description('Create DNS Zones?')
param createDnsZones bool = true
@description('Add Role Assignments for the user assigned identity?')
param addRoleAssignments bool = true
@description('Should we run a script to dedupe the KeyVault secrets? (this fails on private networks right now)')
param deduplicateKeyVaultSecrets bool = false
@description('Set this if you want to append all the resource names with a unique token')
param appendResourceTokens bool = false

// @description('Should UI container app be deployed?')
// param deployUIApp bool = false
@description('Should API container app be deployed?')
param deployAPIApp bool = false
@description('Should Batch container app be deployed?')
param deployBatchApp bool = false

@description('Global Region where the resources will be deployed, e.g. AM (America), EM (EMEA), AP (APAC), CH (China)')
@allowed(['AM', 'EM', 'AP', 'CH'])
param regionCode string = 'AM'

@description('Instance number for the application, e.g. 001, 002, etc. This is used to differentiate multiple instances of the same application in the same environment.')
param instanceNumber string = '001' // used to differentiate multiple instances of the same application in the same environment

// --------------------------------------------------------------------------------------------------------------
// Additional Tags that may be included or not
// --------------------------------------------------------------------------------------------------------------
param costCenterTag string = ''
param ownerEmailTag string = ''
param requestorName string = 'UNKNOWN'
param applicationId string = ''
param primarySupportProviderTag string = ''

// --------------------------------------------------------------------------------------------------------------
// A variable masquerading as a parameter to allow for dynamic value assignment in Bicep
// --------------------------------------------------------------------------------------------------------------
param runDateTime string = utcNow()

// --------------------------------------------------------------------------------------------------------------
// -- Variables -------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
var resourceToken = toLower(uniqueString(resourceGroup().id, location))
var resourceGroupName = resourceGroup().name

// if user supplied a full application name, use that, otherwise use default prefix and a unique token
var appName = applicationName != '' ? applicationName : '${applicationPrefix}_${resourceToken}'

var deploymentSuffix = '-${runDateTime}'

var commonTags = {
  'creation-date': take(runDateTime, 8)
  'application-name': appName
  'application-id': applicationId
  'environment-name': environmentName
  'global-region': regionCode
  'requestor-name': requestorName
  'primary-support-provider': primarySupportProviderTag == '' ? 'UNKNOWN' : primarySupportProviderTag
}
var costCenterTagObject = costCenterTag == '' ? {} :  { 'cost-center': costCenterTag }
var ownerEmailTagObject = ownerEmailTag == '' ? {} :  { 
  'application-owner': ownerEmailTag
  'business-owner': ownerEmailTag
  'point-of-contact': ownerEmailTag
}
// if this bicep was called from AZD, then it needs this tag added to the resource group (at a minimum) to deploy successfully...
var azdTag = azdEnvName != '' ? { 'azd-env-name': azdEnvName } : {}
var tags = union(commonTags, azdTag, costCenterTagObject, ownerEmailTagObject)

// Run a script to dedupe the KeyVault secrets -- this fails on private networks right now so turn if off for them
var deduplicateKVSecrets = publicAccessEnabled ? deduplicateKeyVaultSecrets : false

// --------------------------------------------------------------------------------------------------------------
// -- Generate Resource Names -----------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module resourceNames 'resourcenames.bicep' = {
  name: 'resource-names${deploymentSuffix}'
  params: {
    applicationName: appName
    environmentName: environmentName
    resourceToken: appendResourceTokens ? resourceToken : ''
    regionCode: regionCode
    instance: instanceNumber
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- VNET ------------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module vnet './modules/networking/vnet.bicep' = if (deployVNET) {
  name: 'vnet${deploymentSuffix}'
  params: {
    location: location
    existingVirtualNetworkName: existingVnetName
    existingVnetResourceGroupName: existingVnetResourceGroupName
    newVirtualNetworkName: resourceNames.outputs.vnet_Name
    vnetAddressPrefix: vnetAddressPrefix
    subnetAppGwName: !empty(subnetAppGwName) ? subnetAppGwName  : resourceNames.outputs.subnetAppGwName
    subnetAppGwPrefix: subnetAppGwPrefix 
    subnetAppSeName: !empty(subnetAppSeName ) ? subnetAppSeName  : resourceNames.outputs.subnetAppSeName
    subnetAppSePrefix: subnetAppSePrefix
    subnetPeName: !empty(subnetPeName  ) ? subnetPeName   : resourceNames.outputs.subnetPeName 
    subnetPePrefix : subnetPePrefix 
    subnetAgentName: !empty(subnetAgentName) ? subnetAgentName : resourceNames.outputs.subnetAgentName
    subnetAgentPrefix: subnetAgentPrefix
    subnetBastionName: !empty(subnetBastionName) ? subnetBastionName : resourceNames.outputs.subnetBastionName
    subnetBastionPrefix: subnetBastionPrefix
    subnetJumpboxName: !empty(subnetJumpboxName) ? subnetJumpboxName : resourceNames.outputs.subnetJumpboxName
    subnetJumpboxPrefix: subnetJumpboxPrefix
    subnetTrainingName: !empty(subnetTrainingName) ? subnetTrainingName : resourceNames.outputs.subnetTrainingName
    subnetTrainingPrefix: subnetTrainingPrefix
    subnetScoringName: !empty(subnetScoringName) ? subnetScoringName : resourceNames.outputs.subnetScoringName
    subnetScoringPrefix: subnetScoringPrefix
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- JumpBox ------------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module virtualMachine './modules/virtualMachine/virtualMachine.bicep' = if (!empty(admin_username) && !empty(admin_password) && !empty(vm_name)) {
  name: 'jumpboxVirtualMachineDeployment'
  params: {
    // Required parameters
    admin_username: admin_username 
    admin_password: admin_password 
    vnet_id: vnet.outputs.vnetResourceId
    vm_name: !empty(vm_name) ? vm_name : resourceNames.outputs.vm_name
    vm_nic_name: resourceNames.outputs.vm_nic_name
    vm_pip_name: resourceNames.outputs.vm_pip_name
    vm_os_disk_name: resourceNames.outputs.vm_os_disk_name
    vm_nsg_name: resourceNames.outputs.vm_nsg_name
    
    subnet_name: !empty(subnetJumpboxName) ? subnetJumpboxName : resourceNames.outputs.subnetJumpboxName
    // VM configuration
    vm_size: 'Standard_B2s_v2'
    os_disk_size_gb: 128
    os_type: 'Windows'
    my_ip_address: myIpAddress
    // Location and tags
    location: location
    tags: tags
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- Container Registry ----------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module containerRegistry './modules/app/containerregistry.bicep' = {
  name: 'containerregistry${deploymentSuffix}'
  params: {
    newRegistryName: resourceNames.outputs.ACR_Name
    location: location
    acrSku: 'Premium'
    tags: tags
    publicAccessEnabled: publicAccessEnabled
    privateEndpointName: 'pe-${resourceNames.outputs.ACR_Name}'
    privateEndpointSubnetId: deployVNET ? vnet.outputs.subnetPeResourceID : ''
    myIpAddress: myIpAddress
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- Log Analytics Workspace and App Insights ------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module logAnalytics './modules/monitor/loganalytics.bicep' = {
  name: 'law${deploymentSuffix}'
  params: {
    newLogAnalyticsName: resourceNames.outputs.logAnalyticsWorkspaceName
    newApplicationInsightsName: resourceNames.outputs.appInsightsName
    location: location
    tags: tags
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- Storage Resources ---------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module storage './modules/storage/storage-account.bicep' = {
  name: 'storage${deploymentSuffix}'
  params: {
    name: resourceNames.outputs.storageAccountName
    location: location
    tags: tags
    // publicNetworkAccess: publicAccessEnabled
    privateEndpointSubnetId: deployVNET ? vnet.outputs.subnetPeResourceID : ''
    privateEndpointBlobName: 'pe-blob-${resourceNames.outputs.storageAccountName}'
    privateEndpointQueueName: 'pe-queue-${resourceNames.outputs.storageAccountName}'
    privateEndpointTableName: 'pe-table-${resourceNames.outputs.storageAccountName}'
    myIpAddress: myIpAddress
    containers: ['data', 'batch-input', 'batch-output']
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- Identity and Access Resources -----------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module identity './modules/iam/identity.bicep' = {
  name: 'app-identity${deploymentSuffix}'
  params: {
    identityName: resourceNames.outputs.userAssignedIdentityName
    location: location
  }
}
module appIdentityRoleAssignments './modules/iam/role-assignments.bicep' = if (addRoleAssignments) {
  name: 'identity-roles${deploymentSuffix}'
  params: {
    identityPrincipalId: identity.outputs.managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    registryName: containerRegistry.outputs.name
    storageAccountName: storage.outputs.name
    aiSearchName: searchService.outputs.name
    aiServicesName: openAI.outputs.name
    cosmosName: cosmos.outputs.name
  }
}

module adminUserRoleAssignments './modules/iam/role-assignments.bicep' = if (addRoleAssignments && !empty(principalId)) {
  name: 'user-roles${deploymentSuffix}'
  params: {
    identityPrincipalId: principalId
    principalType: 'User'
    registryName: containerRegistry.outputs.name
    storageAccountName: storage.outputs.name
    aiSearchName: searchService.outputs.name
    aiServicesName: openAI.outputs.name
    cosmosName: cosmos.outputs.name
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- Key Vault Resources ---------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module keyVault './modules/security/keyvault.bicep' = {
  name: 'keyvault${deploymentSuffix}'
  params: {
    location: location
    commonTags: tags
    keyVaultName: resourceNames.outputs.keyVaultName
    keyVaultOwnerUserId: principalId
    adminUserObjectIds: [identity.outputs.managedIdentityPrincipalId]
    publicNetworkAccess: publicAccessEnabled ? 'Enabled' : 'Disabled'
    keyVaultOwnerIpAddress: myIpAddress
    createUserAssignedIdentity: false
    privateEndpointName: 'pe-${resourceNames.outputs.keyVaultName}'
    privateEndpointSubnetId: deployVNET ? vnet.outputs.subnetPeResourceID : ''
  }
}

module keyVaultSecretList './modules/security/keyvault-list-secret-names.bicep' = if (deduplicateKVSecrets) {
  name: 'keyVault-Secret-List-Names${deploymentSuffix}'
  params: {
    keyVaultName: keyVault.outputs.name
    location: location
    userManagedIdentityId: identity.outputs.managedIdentityId
  }
}

var apiKeyValue = uniqueString(resourceGroup().id, location, 'api-key', runDateTime)
module apiKeySecret './modules/security/keyvault-secret.bicep' = {
  name: 'secret-api-key${deploymentSuffix}'
  params: {
    keyVaultName: keyVault.outputs.name
    secretName: 'api-key'
    existingSecretNames: deduplicateKVSecrets ? keyVaultSecretList.outputs.secretNameList : ''
    secretValue: apiKeyValue
  }
}

module cosmosSecret './modules/security/keyvault-cosmos-secret.bicep' = {
  name: 'secret-cosmos${deploymentSuffix}'
  params: {
    keyVaultName: keyVault.outputs.name
    secretName: cosmos.outputs.keyVaultSecretName
    cosmosAccountName: cosmos.outputs.name
    existingSecretNames: deduplicateKVSecrets ? keyVaultSecretList.outputs.secretNameList : ''
  }
}

module storageSecret './modules/security/keyvault-storage-secret.bicep' = {
  name: 'secret-storage${deploymentSuffix}'
  params: {
    keyVaultName: keyVault.outputs.name
    secretName: storage.outputs.storageAccountConnectionStringSecretName
    storageAccountName: storage.outputs.name
    existingSecretNames: deduplicateKVSecrets ? keyVaultSecretList.outputs.secretNameList : ''
  }
}

module openAISecret './modules/security/keyvault-cognitive-secret.bicep' = {
  name: 'secret-openai${deploymentSuffix}'
  params: {
    keyVaultName: keyVault.outputs.name
    secretName: openAI.outputs.cognitiveServicesKeySecretName
    cognitiveServiceName: openAI.outputs.name
    cognitiveServiceResourceGroup: openAI.outputs.resourceGroupName
    existingSecretNames: deduplicateKVSecrets ? keyVaultSecretList.outputs.secretNameList : ''
  }
}

module documentIntelligenceSecret './modules/security/keyvault-cognitive-secret.bicep' = {
  name: 'secret-doc-intelligence${deploymentSuffix}'
  params: {
    keyVaultName: keyVault.outputs.name
    secretName: documentIntelligence.outputs.keyVaultSecretName
    cognitiveServiceName: documentIntelligence.outputs.name
    cognitiveServiceResourceGroup: documentIntelligence.outputs.resourceGroupName
    existingSecretNames: deduplicateKVSecrets ? keyVaultSecretList.outputs.secretNameList : ''
  }
}

module searchSecret './modules/security/keyvault-search-secret.bicep' = {
  name: 'secret-search${deploymentSuffix}'
  params: {
    keyVaultName: keyVault.outputs.name
    secretName: searchService.outputs.keyVaultSecretName
    searchServiceName: searchService.outputs.name
    searchServiceResourceGroup: searchService.outputs.resourceGroupName
    existingSecretNames: deduplicateKVSecrets ? keyVaultSecretList.outputs.secretNameList : ''
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- Cosmos Resources ------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
var uiDatabaseName = 'ChatHistory'
var uiChatContainerName = 'ChatTurn'
var uiChatContainerName2 = 'ChatHistory'
var cosmosContainerArray = [
  { name: 'AgentLog', partitionKey: '/requestId' }
  { name: 'UserDocuments', partitionKey: '/userId' }
  { name: uiChatContainerName, partitionKey: '/chatId' }
  { name: uiChatContainerName2, partitionKey: '/chatId' }
]
module cosmos './modules/database/cosmosdb.bicep' = {
  name: 'cosmos${deploymentSuffix}'
  params: {
    accountName: resourceNames.outputs.cosmosName
    databaseName: uiDatabaseName
    containerArray: cosmosContainerArray
    location: location
    tags: tags
    privateEndpointSubnetId: deployVNET ? vnet.outputs.subnetPeResourceID : ''
    privateEndpointName: 'pe-${resourceNames.outputs.cosmosName}'
    managedIdentityPrincipalId: identity.outputs.managedIdentityPrincipalId
    userPrincipalId: principalId
    publicNetworkAccess: publicAccessEnabled ? 'enabled' : 'disabled'
    myIpAddress: myIpAddress
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- Search Service Resource ------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module searchService './modules/search/search-services.bicep' = {
  name: 'search${deploymentSuffix}'
  params: {
    location: location
    name: resourceNames.outputs.searchServiceName
    publicNetworkAccess: publicAccessEnabled ? 'enabled' : 'disabled'
    myIpAddress: myIpAddress
    privateEndpointSubnetId: deployVNET ? vnet.outputs.subnetPeResourceID : ''
    privateEndpointName: 'pe-${resourceNames.outputs.searchServiceName}'
    managedIdentityId: identity.outputs.managedIdentityId
    sku: {
      name: 'basic'
    }
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- Azure OpenAI Resources ------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module openAI './modules/ai/cognitive-services.bicep' = {
  name: 'openai${deploymentSuffix}'
  params: {
    managedIdentityId: identity.outputs.managedIdentityId
    name: resourceNames.outputs.cogServiceName
    location: openAI_deploy_location // this may be different than the other resources
    pe_location: location
    appInsightsName: logAnalytics.outputs.applicationInsightsName
    tags: tags
    textEmbeddings: [{
      name: 'text-embedding'
      model: {
        format: 'OpenAI'
        name: 'text-embedding-ada-002'
        version: '2'
      }
    }]
    chatGpt_Standard: {
      DeploymentName: 'gpt-35-turbo'
      ModelName: 'gpt-35-turbo'
      ModelVersion: '0125'
      DeploymentCapacity: 10
    }
    chatGpt_Premium: {
      DeploymentName: 'gpt-4o'
      ModelName: 'gpt-4o'
      ModelVersion: '2024-08-06'
      DeploymentCapacity: 10
    }
    publicNetworkAccess: publicAccessEnabled ? 'enabled' : 'disabled'
    privateEndpointSubnetId: deployVNET ? vnet.outputs.subnetPeResourceID : ''
    privateEndpointName: 'pe-${resourceNames.outputs.cogServiceName}'
    myIpAddress: myIpAddress
  }
  dependsOn: [
    searchService
  ]
}

module documentIntelligence './modules/ai/document-intelligence.bicep' = {
  name: 'doc-intelligence${deploymentSuffix}'
  params: {
    name: resourceNames.outputs.documentIntelligenceName
    location: location // this may be different than the other resources
    tags: tags
    publicNetworkAccess: publicAccessEnabled ? 'enabled' : 'disabled'
    privateEndpointSubnetId: deployVNET ? vnet.outputs.subnetPeResourceID : ''
    privateEndpointName: 'pe-${resourceNames.outputs.documentIntelligenceName}'
    myIpAddress: myIpAddress
    managedIdentityId: identity.outputs.managedIdentityId
  }
  dependsOn: [
    searchService
  ]
}

// --------------------------------------------------------------------------------------------------------------
// AI Foundry Hub and Project V2
// Imported from https://github.com/adamhockemeyer/ai-agent-experience
// --------------------------------------------------------------------------------------------------------------
module aiFoundryHub './modules/ai-foundry/ai-foundry-hub.bicep' = {
  name:  'aiHub${deploymentSuffix}'
  params: {
    location: location
    name: resourceNames.outputs.aiHubName
    tags: commonTags
    applicationInsightsId: logAnalytics.outputs.applicationInsightsId
    storageAccountId: storage.outputs.id
    aiServiceKind: openAI.outputs.kind
    aiServicesId: openAI.outputs.id
    aiServicesName: openAI.outputs.name
    aiServicesTarget: openAI.outputs.endpoint
    //aoaiModelDeployments: openAI.outputs.deployments
    aiSearchId: searchService.outputs.id
    aiSearchName: searchService.outputs.name
  }
}

module aiFoundryProject './modules/ai-foundry/ai-foundry-project.bicep' = {
  name: 'aiFoundryProject${deploymentSuffix}'
  params: {
    location: location
    name: resourceNames.outputs.aiHubFoundryProjectName
    tags: commonTags
    hubId: aiFoundryHub.outputs.id
    //hubName: aiFoundryHub.outputs.name
    //aiServicesConnectionName: [aiFoundryHub.outputs.connection_aisvcName]
  }
}
module aiFoundryIdentityRoleAssignments './modules/iam/role-assignments.bicep' = if (addRoleAssignments) {
  name: 'foundry-roles${deploymentSuffix}'
  params: {
    identityPrincipalId: aiFoundryProject.outputs.principalId
    principalType: 'ServicePrincipal'
    aiServicesName: openAI.outputs.name
  }
}

// AI Project and Capability Host
module aiProject './modules/cognitive-services/ai-project.bicep' = {
  name: 'aiProject${deploymentSuffix}'
  params: {
    location: location
    accountName: openAI.outputs.name
    projectName:  resourceNames.outputs.aiHubProjectName
    projectDescription:aiProjectDescription
    displayName: aiProjectFriendlyName
    // Connect to existing resources
    aiSearchName: searchService.outputs.name
    aiSearchServiceResourceGroupName: resourceGroup().name
    aiSearchServiceSubscriptionId: subscription().subscriptionId

    cosmosDBName: cosmos.outputs.name
    cosmosDBResourceGroupName: resourceGroup().name
    cosmosDBSubscriptionId: subscription().subscriptionId

    azureStorageName: storage.outputs.name
    azureStorageResourceGroupName: resourceGroup().name
    azureStorageSubscriptionId: subscription().subscriptionId

    // // Connect to App Insights
    // appInsightsName: logAnalytics.outputs.applicationInsightsName
    // appInsightsResourceGroupName: resourceGroup().name
    // appInsightsSubscriptionId: subscription().subscriptionId
  }
}

module formatProjectWorkspaceId './modules/cognitive-services/format-project-workspace-id.bicep' = {
  name: 'aiProjectFormatWorkspaceId${deploymentSuffix}'
  params: {
    projectWorkspaceId: aiProject.outputs.projectWorkspaceId
  }
}

// --------------------------------------------------------------------------------------------------------------
// AI Foundry Hub and Project V1
// Imported from https://github.com/msft-mfg-ai/smart-flow-public
// --------------------------------------------------------------------------------------------------------------
// module aiHub_v1 './modules/ai/ai-hub-secure.bicep' = if (deployAIHub) {
//   name: 'aiHub${deploymentSuffix}'
//   params: {
//     aiHubName: resourceNames.outputs.aiHubName
//     location: location
//     tags: tags

//     // dependent resources
//     aiServicesId: openAI.outputs.id
//     aiServicesTarget: openAI.outputs.endpoint
//     aiSearchName: searchService.outputs.name
//     applicationInsightsId: logAnalytics.outputs.applicationInsightsId
//     containerRegistryId: containerRegistry.outputs.id
//     keyVaultId: keyVault.outputs.id
//     storageAccountId: storage.outputs.id

//     // add data scientist role to user and application
//     addRoleAssignments: addRoleAssignments
//     userObjectId: principalId
//     userObjectType: 'User'
//     managedIdentityPrincipalId: identity.outputs.managedIdentityPrincipalId
//     managedIdentityType: 'ServicePrincipal'
//   }
// }

// module aiProject_v1 './modules/ai/ai-hub-project.bicep' = if (deployAIHub) {
//   name: 'aiProject${deploymentSuffix}'
//   params: {
//     aiProjectName: resourceNames.outputs.aiHubProjectName
//     aiProjectFriendlyName: aiProjectFriendlyName
//     aiProjectDescription: aiProjectDescription
//     location: location
//     tags: tags
//     aiHubId: aiHub.outputs.id
//   }
// }

// --------------------------------------------------------------------------------------------------------------
// -- APIM ------------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module apim './modules/api-management/apim.bicep' = if (deployAPIM) {
  name: 'apim${deploymentSuffix}'
  params: {
    location: location
    name: resourceNames.outputs.apimName
    commonTags: commonTags
    publisherEmail: apimPublisherEmail
    publisherName: adminPublisherName
    appInsightsName: logAnalytics.outputs.applicationInsightsName
    subscriptionName: apimSubscriptionName
  }
}

module apimConfiguration './modules/api-management/apim-oai-config.bicep' = if (deployAPIM) {
  name: 'apimConfig${deploymentSuffix}'
  params: {
    apimName: apim.outputs.name
    apimLoggerName: apim.outputs.loggerName
    cognitiveServicesName: openAI.outputs.name
  }
}

module apimIdentityRoleAssignments './modules/iam/role-assignments.bicep' = if (deployAPIM && addRoleAssignments) {
  name: 'apim-roles${deploymentSuffix}'
  params: {
    identityPrincipalId: aiFoundryProject.outputs.principalId
    principalType: 'ServicePrincipal'
    apimName: apim.outputs.name
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- DNS ZONES ---------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module allDnsZones './modules/networking/all-zones.bicep' = if (deployVNET && createDnsZones) {
  name: 'all-dns-zones${deploymentSuffix}'
  params: {
    tags: tags
    vnetResourceId: vnet.outputs.vnetResourceId

    keyVaultPrivateEndpointName: keyVault.outputs.privateEndpointName
    acrPrivateEndpointName: containerRegistry.outputs.privateEndpointName
    openAiPrivateEndpointName: openAI.outputs.privateEndpointName
    aiSearchPrivateEndpointName: searchService.outputs.privateEndpointName
    documentIntelligencePrivateEndpointName: documentIntelligence.outputs.privateEndpointName
    cosmosPrivateEndpointName: cosmos.outputs.privateEndpointName
    storageBlobPrivateEndpointName: storage.outputs.privateEndpointBlobName
    storageQueuePrivateEndpointName: storage.outputs.privateEndpointQueueName
    storageTablePrivateEndpointName: storage.outputs.privateEndpointTableName

    defaultAcaDomain: managedEnvironment.outputs.defaultDomain
    acaStaticIp: managedEnvironment.outputs.staticIp
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- Container App Environment ---------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module managedEnvironment './modules/app/managedEnvironment.bicep' = {
  name: 'caenv${deploymentSuffix}'
  params: {
    newEnvironmentName: resourceNames.outputs.caManagedEnvName
    location: location
    logAnalyticsWorkspaceName: logAnalytics.outputs.logAnalyticsWorkspaceName
    logAnalyticsRgName: resourceGroupName
    appSubnetId: deployVNET ? vnet.outputs.subnetAppSeResourceID : ''
    tags: tags
    publicAccessEnabled: publicAccessEnabled
    containerAppEnvironmentWorkloadProfiles: containerAppEnvironmentWorkloadProfiles
  }
}

var apiTargetPort = 8080
var apiSettings = [
  { name: 'AnalysisApiEndpoint', value: 'https://${resourceNames.outputs.containerAppAPIName}.${managedEnvironment.outputs.defaultDomain}' }
  { name: 'AnalysisApiKey', secretRef: 'apikey' }
  { name: 'AOAIStandardServiceEndpoint', value: openAI.outputs.endpoint }
  { name: 'AOAIStandardChatGptDeployment', value: 'gpt-4o' }
  { name: 'ApiKey', secretRef: 'apikey' }
  { name: 'PORT', value: '${apiTargetPort}' }
  { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', value: logAnalytics.outputs.appInsightsConnectionString }
  { name: 'AZURE_CLIENT_ID', value: identity.outputs.managedIdentityClientId }
  { name: 'AzureDocumentIntelligenceEndpoint', value: documentIntelligence.outputs.endpoint }
  { name: 'AzureAISearchEndpoint', value: searchService.outputs.endpoint }
  { name: 'ContentStorageContainer', value: storage.outputs.containerNames[0].name }
  { name: 'CosmosDbEndpoint', value: cosmos.outputs.endpoint }
  { name: 'StorageAccountName', value: storage.outputs.name }
]

module containerAppAPI './modules/app/containerappstub.bicep' = if (deployAPIApp) {
  name: 'ca-api-stub${deploymentSuffix}'
  params: {
    appName: resourceNames.outputs.containerAppAPIName
    managedEnvironmentName: managedEnvironment.outputs.name
    managedEnvironmentRg: managedEnvironment.outputs.resourceGroupName
    workloadProfileName: appContainerAppEnvironmentWorkloadProfileName
    registryName: resourceNames.outputs.ACR_Name
    targetPort: apiTargetPort
    userAssignedIdentityName: identity.outputs.managedIdentityName
    location: location
    imageName: apiImageName
    tags: union(tags, { 'azd-service-name': 'api' })
    deploymentSuffix: deploymentSuffix
    secrets: {
      cosmos: cosmosSecret.outputs.secretUri
      aikey: openAISecret.outputs.secretUri
      docintellikey: documentIntelligenceSecret.outputs.secretUri
      searchkey: searchSecret.outputs.secretUri
      apikey: apiKeySecret.outputs.secretUri
    }
    env: apiSettings
  }
  dependsOn: createDnsZones ? [allDnsZones, containerRegistry] : [containerRegistry]
}

var batchTargetPort = 8080
var batchSettings = union(apiSettings, [
  { name: 'FUNCTIONS_WORKER_RUNTIME', value: 'dotnet-isolated' }
  // see: https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-functions-configure-managed-identity
  { name: 'AzureWebJobsStorage__accountName', value: storage.outputs.name }
  { name: 'AzureWebJobsStorage__credential', value: 'managedidentity' }
  { name: 'AzureWebJobsStorage__clientId', value: identity.outputs.managedIdentityClientId }
  { name: 'BatchAnalysisStorageAccountName', value: storage.outputs.name }
  { name: 'BatchAnalysisStorageInputContainerName', value: storage.outputs.containerNames[1].name }
  { name: 'BatchAnalysisStorageOutputContainerName', value: storage.outputs.containerNames[2].name }
  { name: 'CosmosDbDatabaseName', value: cosmos.outputs.databaseName }
  { name: 'CosmosDbContainerName', value: uiChatContainerName }
  { name: 'MaxBatchSize', value: '10' }
])
module containerAppBatch './modules/app/containerappstub.bicep' = if (deployBatchApp) {
  name: 'ca-batch-stub${deploymentSuffix}'
  params: {
    appName: resourceNames.outputs.containerAppBatchName
    managedEnvironmentName: managedEnvironment.outputs.name
    managedEnvironmentRg: managedEnvironment.outputs.resourceGroupName
    workloadProfileName: appContainerAppEnvironmentWorkloadProfileName
    registryName: resourceNames.outputs.ACR_Name
    targetPort: batchTargetPort
    userAssignedIdentityName: identity.outputs.managedIdentityName
    location: location
    imageName: batchImageName
    tags: union(tags, { 'azd-service-name': 'batch' })
    deploymentSuffix: deploymentSuffix
    secrets: {
      cosmos: cosmosSecret.outputs.secretUri
      aikey: openAISecret.outputs.secretUri
      docintellikey: documentIntelligenceSecret.outputs.secretUri
      searchkey: searchSecret.outputs.secretUri
      apikey: apiKeySecret.outputs.secretUri
    }
    env: batchSettings
  }
  dependsOn: createDnsZones ? [allDnsZones, containerRegistry] : [containerRegistry]
}

// --------------------------------------------------------------------------------------------------------------
// -- Bastion Host ----------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
// Deploy Bastion Host for secure VM access
module bastion './modules/networking/bastion.bicep' = {
  name: 'bastionDeployment'
  params: {
    name: resourceNames.outputs.bastion_host_name
    location: location
    publicIPName: resourceNames.outputs.bastion_pip_name
    subnetId: vnet.outputs.subnetBastionResourceID  // Make sure this output exists in your vnet module
    tags: tags
    enableTunneling: true
    enableFileCopy: true
    skuName: 'Standard'
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- Outputs ---------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
output SUBSCRIPTION_ID string = subscription().subscriptionId
output ACR_NAME string = containerRegistry.outputs.name
output ACR_URL string = containerRegistry.outputs.loginServer
output AI_ENDPOINT string = openAI.outputs.endpoint
output AI_HUB_ID string = deployAIHub ? aiFoundryHub.outputs.id : ''
output AI_HUB_NAME string = deployAIHub ? aiFoundryHub.outputs.name : ''
output AI_PROJECT_NAME string = resourceNames.outputs.aiHubProjectName
output AI_SEARCH_ENDPOINT string = searchService.outputs.endpoint
output API_CONTAINER_APP_FQDN string = deployAPIApp ? containerAppAPI.outputs.fqdn : ''
output API_CONTAINER_APP_NAME string = deployAPIApp ? containerAppAPI.outputs.name : ''
output API_KEY string = apiKeyValue
output API_MANAGEMENT_ID string = deployAPIM ? apim.outputs.id : ''
output API_MANAGEMENT_NAME string = deployAPIM ? apim.outputs.name : ''
output AZURE_CONTAINER_ENVIRONMENT_NAME string = managedEnvironment.outputs.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
output AZURE_RESOURCE_GROUP string = resourceGroupName
output COSMOS_CONTAINER_NAME string = uiChatContainerName
output COSMOS_DATABASE_NAME string = cosmos.outputs.databaseName
output COSMOS_ENDPOINT string = cosmos.outputs.endpoint
output DOCUMENT_INTELLIGENCE_ENDPOINT string = documentIntelligence.outputs.endpoint
output MANAGED_ENVIRONMENT_ID string = managedEnvironment.outputs.id
output MANAGED_ENVIRONMENT_NAME string = managedEnvironment.outputs.name
output RESOURCE_TOKEN string = resourceToken
output STORAGE_ACCOUNT_BATCH_IN_CONTAINER string = storage.outputs.containerNames[1].name
output STORAGE_ACCOUNT_BATCH_OUT_CONTAINER string = storage.outputs.containerNames[2].name
output STORAGE_ACCOUNT_CONTAINER string = storage.outputs.containerNames[0].name
output STORAGE_ACCOUNT_NAME string = storage.outputs.name
output VNET_CORE_ID string = deployVNET ? vnet.outputs.vnetResourceId : ''
output VNET_CORE_NAME string = deployVNET ? vnet.outputs.vnetName : ''
output VNET_CORE_PREFIX string = deployVNET ? vnet.outputs.vnetAddressPrefix : ''
