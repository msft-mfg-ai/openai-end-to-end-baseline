// --------------------------------------------------------------------------------------------------------------
// Main bicep file that deploys a advanced version of the LZ with
//   Private Networking, includes EVERYTHING for the application,
//   with optional parameters for existing resources.
// --------------------------------------------------------------------------------------------------------------
// You can test before deploy it with this command (run these commands in the same directory as this bicep file):
//   az deployment group what-if --resource-group rg_mfg-ai-lz --template-file 'main-advanced.bicep' --parameters environmentName=dev applicationName=otaiexp applicationId=otaiexp1 instanceNumber=002 regionCode=naa
// You can deploy it with this command:
//   az deployment group create -n manual --resource-group rg_mfg-ai-lz --template-file 'main-advanced.bicep' --parameters environmentName=dev applicationName=otaiexp applicationId=otaiexp1 instanceNumber=002 regionCode=naa
// Or with a parameter file:
//   az deployment group create -n manual --resource-group rg_mfg-ai-lz --template-file 'main-advanced.bicep' --parameters main-advanced.your.bicepparam
// --------------------------------------------------------------------------------------------------------------
// 	Services Needed for Chat Agent Programs:
// 		Container Apps
//    Container Registry
// 		CosmosDB
// 		Storage Account
//    Key Vault (APIM Subscription key, certificates)
// 		Azure Foundry (includes Azure Open AI)
//    APIM (may already have existing instance)
//    Advanced Private Networking Features
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
param applicationPrefix string = ''

@description('The environment code (i.e. dev, qa, prod)')
param environmentName string = ''
// @description('Environment name used by the azd command (optional)')
// param azdEnvName string = ''

@description('Primary location for all resources')
param location string = resourceGroup().location

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
param subnetAppGwPrefix string = cidrSubnet(vnetPrefix, 24, 1) // '10.183.5.0/24'
param subnetAppSeName string = ''
param subnetAppSePrefix string = cidrSubnet(vnetPrefix, 24, 0) // 10.183.4.0/24
param subnetPeName string = ''
param subnetPePrefix string = cidrSubnet(vnetPrefix, 27, 16) // 10.183.6.0/27
param subnetAgentName string = ''
param subnetAgentPrefix string = cidrSubnet(vnetPrefix, 27, 17) // 10.183.6.32/27
param subnetBastionName string = '' // This is the default for the MFG AI LZ, it can be changed to fit your needs
param subnetBastionPrefix string = cidrSubnet(vnetPrefix, 26, 9) // 10.183.6.64/26
param subnetJumpboxName string = '' // This is the default for the MFG AI LZ, it can be changed to fit your needs
param subnetJumpboxPrefix string = cidrSubnet(vnetPrefix, 28, 40) // 10.183.6.128/28
param subnetTrainingName string = ''
param subnetTrainingPrefix string = cidrSubnet(vnetPrefix, 25, 6) // 10.183.7.0/25
param subnetScoringName string = ''
param subnetScoringPrefix string = cidrSubnet(vnetPrefix, 25, 7) // 10.183.7.128/25

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

// --------------------------------------------------------------------------------------------------------------
// Container App Environment
// --------------------------------------------------------------------------------------------------------------
@description('Name of the Container Apps Environment workload profile to use for the app')
param appContainerAppEnvironmentWorkloadProfileName string = containerAppEnvironmentWorkloadProfiles[0].name
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
// Container App Entra Parameters
// -------------------------------------------------------------------------------------------------------------`
param entraTenantId string = tenant().tenantId
param entraApiAudience string = ''
param entraScopes string = ''
@description('Entra Redirect URI for the application. Only required for custom domains. Should end with /auth/callback')
param entraRedirectUri string?
@secure()
param entraClientId string = ''
@secure()
param entraClientSecret string = ''

// --------------------------------------------------------------------------------------------------------------
// Foundry Parameters
// --------------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------------
// AI Models
// --------------------------------------------------------------------------------------------------------------
@description('The default GPT 4o model deployment name for the AI Agent')
param gpt40_DeploymentName string = 'gpt-4o' 
@description('The GPT 4o model version to use')
param gpt40_ModelVersion string = '2024-11-20'
@description('The GPT 4o model deployment capacity')
param gpt40_DeploymentCapacity int = 10

@description('The default GPT 4.1 model deployment name for the AI Agent')
param gpt41_DeploymentName string = 'gpt-4.1'
@description('The GPT 4.1 model version to use')
param gpt41_ModelVersion string = '2025-04-14'
@description('The GPT 4.1 model deployment capacity')
param gpt41_DeploymentCapacity int = 10

// --------------------------------------------------------------------------------------------------------------
// APIM Parameters
// --------------------------------------------------------------------------------------------------------------
@description('Should we deploy an APIM?')
param deployAPIM bool = false
@description('Name of the APIM Subscription. Defaults to aiagent-subscription')
param apimSubscriptionName string = 'aiagent-subscription'
@description('Email of the APIM Publisher')
param apimPublisherEmail string = 'somebody@somewhere.com'
@description('Name of the APIM Publisher')
param adminPublisherName string = 'AI Agent Admin'

// --------------------------------------------------------------------------------------------------------------
// External APIM Parameters
// --------------------------------------------------------------------------------------------------------------
@description('Base URL to facade API')
param apimBaseUrl string = ''
param apimAccessUrl string = ''
@secure()
param apimAccessKey string = ''
@description('When set to true, UPN received from the authentication will be mocked to a fixed value')
param mockUserUpn bool = false

// --------------------------------------------------------------------------------------------------------------
// Application Gateway Parameters
// --------------------------------------------------------------------------------------------------------------
@description('Should we deploy an Application Gateway?')
param deployApplicationGateway bool = true
@description('Application Gateway SKU')
@allowed(['Standard_v2', 'WAF_v2'])
param appGatewaySkuName string = 'WAF_v2'
@description('Application Gateway minimum capacity for autoscaling')
@minValue(0)
@maxValue(100)
param appGatewayMinCapacity int = 1
@description('Application Gateway maximum capacity for autoscaling')
@minValue(2)
@maxValue(100)
param appGatewayMaxCapacity int = 10
@description('Enable HTTP2 on Application Gateway')
param appGatewayEnableHttp2 bool = true
@description('Enable FIPS on Application Gateway')
param appGatewayEnableFips bool = false
@description('Backend address pools for Application Gateway (FQDNs or IP addresses)')
param appGatewayBackendAddresses array = []
@description('DNS label prefix for Application Gateway public IP')
param appGatewayDnsLabelPrefix string = ''
@description('SSL certificate Key Vault secret URI')
@secure()
param appGatewaySslCertificateKeyVaultSecretId string = ''

// --------------------------------------------------------------------------------------------------------------
// Existing images
// --------------------------------------------------------------------------------------------------------------
param apiImageName string?
param uiImageName string?

// --------------------------------------------------------------------------------------------------------------
// Other deployment switches
// --------------------------------------------------------------------------------------------------------------
@description('Should resources be created with public access?')
param publicAccessEnabled bool = false
@description('Create DNS Zones?')
param createDnsZones bool = true
@description('Add Role Assignments for the user assigned identity?')
param addRoleAssignments bool = true
@description('Should we run a script to dedupe the KeyVault secrets? (this fails on private networks right now)')
param deduplicateKeyVaultSecrets bool = false
@description('Set this if you want to append all the resource names with a unique token')
param appendResourceTokens bool = false

@description('Should API container app be deployed?')
param deployAPIApp bool = false
@description('Should UI container app be deployed?')
param deployUIApp bool = false
@description('Should we deploy a Document Intelligence?')
param deployDocumentIntelligence bool = false

@description('Global Region where the resources will be deployed, e.g. AM (America), EM (EMEA), AP (APAC), CH (China)')
//@allowed(['AM', 'EM', 'AP', 'CH', 'NAA'])
param regionCode string = 'NAA'

@description('Instance number for the application, e.g. 001, 002, etc. This is used to differentiate multiple instances of the same application in the same environment.')
param instanceNumber string = '001' // used to differentiate multiple instances of the same application in the same environment

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
var resourceToken = toLower(uniqueString(resourceGroup().id, location))
var resourceGroupName = resourceGroup().name

// if user supplied a full application name, use that, otherwise use default prefix and a unique token
var appName = applicationName != '' ? applicationName : '${applicationPrefix}_${resourceToken}'

var deploymentSuffix = '-${resourceToken}'

var tags = {
  'creation-date': take(runDateTime, 8)
  'environment-name': environmentName
  'requestor-name': requestorNameTag
  'application-owner': applicationOwnerTag
  'business-owner': businessOwnerTag
  'created-by': createdByTag
  'application-name': applicationName
  'cost-center': costCenterTag
  'lti-service-class': ltiServiceClassTag
  'otis-region': regionCode
  'primary-support-provider': primarySupportProviderTag
  'request-number': requestNumberTag
}

// Run a script to dedupe the KeyVault secrets -- this fails on private networks right now so turn if off for them
var deduplicateKVSecrets = publicAccessEnabled ? deduplicateKeyVaultSecrets : false

// if either of these are empty or the value is set to string 'null', then we will not deploy the Entra client secrets
var deployEntraClientSecrets = !(empty(entraClientId) || empty(entraClientSecret) || toLower(entraClientId) == 'null' || toLower(entraClientSecret) == 'null')

var deployContainerRegistry = deployAPIApp || deployUIApp
var deployCAEnvironment = deployAPIApp || deployUIApp
var deployVirtualMachine = !empty(admin_username) && !empty(admin_password)

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
    numberOfProjects: numberOfProjects
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- VNET ------------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module vnet './modules/networking/vnet.bicep' = {
  name: 'vnet${deploymentSuffix}'
  params: {
    location: location
    existingVirtualNetworkName: existingVnetName
    existingVnetResourceGroupName: existingVnetResourceGroupName
    newVirtualNetworkName: resourceNames.outputs.vnet_Name
    vnetAddressPrefix: vnetPrefix
    vnetNsgName: resourceNames.outputs.vnetNsgName
    subnetAppGwName: !empty(subnetAppGwName) ? subnetAppGwName : resourceNames.outputs.subnetAppGwName
    subnetAppGwPrefix: subnetAppGwPrefix 
    subnetAppSeName: !empty(subnetAppSeName) ? subnetAppSeName : resourceNames.outputs.subnetAppSeName
    subnetAppSePrefix: subnetAppSePrefix
    subnetPeName: !empty(subnetPeName) ? subnetPeName : resourceNames.outputs.subnetPeName
    subnetPePrefix: subnetPePrefix
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
module virtualMachine './modules/virtualMachine/virtualMachine.bicep' = if (deployVirtualMachine) {
  name: 'jumpboxVirtualMachineDeployment'
  params: {
    // Required parameters
    admin_username: admin_username!
    admin_password: admin_password!
    vnet_id: vnet.outputs.vnetResourceId
    vm_name: !empty(vm_name) ? vm_name! : resourceNames.outputs.vm_name
    vm_computer_name: resourceNames.outputs.vm_name_15
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
module containerRegistry './modules/app/containerregistry.bicep' = if (deployContainerRegistry) {
  name: 'containerregistry${deploymentSuffix}'
  params: {
    newRegistryName: resourceNames.outputs.ACR_Name
    location: location
    acrSku: 'Premium'
    tags: tags
    publicAccessEnabled: publicAccessEnabled
    privateEndpointName: resourceNames.outputs.peAcrName
    privateEndpointSubnetId: vnet.outputs.subnetPeResourceID
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
    privateEndpointSubnetId: vnet.outputs.subnetPeResourceID
    privateEndpointBlobName: resourceNames.outputs.peStorageAccountBlobName
    privateEndpointTableName: resourceNames.outputs.peStorageAccountTableName
    privateEndpointQueueName: resourceNames.outputs.peStorageAccountQueueName
    myIpAddress: myIpAddress
    containers: ['data', 'batch-input', 'batch-output']
    allowSharedKeyAccess: false
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
    registryName: deployContainerRegistry ? containerRegistry!.outputs.name : ''
    storageAccountName: storage.outputs.name
    aiSearchName: searchService.outputs.name
    aiServicesName: aiFoundry.outputs.name
    cosmosName: cosmos.outputs.name
    keyVaultName: keyVault.outputs.name
    apimName: deployAPIM ? apim!.outputs.name : ''
  }
}

module adminUserRoleAssignments './modules/iam/role-assignments.bicep' = if (addRoleAssignments && !empty(principalId)) {
  name: 'user-roles${deploymentSuffix}'
  params: {
    identityPrincipalId: principalId
    principalType: 'User'
    registryName: deployContainerRegistry ? containerRegistry!.outputs.name : ''
    storageAccountName: storage.outputs.name
    aiSearchName: searchService.outputs.name
    aiServicesName: aiFoundry.outputs.name
    cosmosName: cosmos.outputs.name
    keyVaultName: keyVault.outputs.name
    apimName: deployAPIM ? apim!.outputs.name : ''
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
    privateEndpointName: resourceNames.outputs.peKeyVaultName
    privateEndpointSubnetId: vnet.outputs.subnetPeResourceID
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

var apiKeyValue = uniqueString(resourceGroup().id, location, 'api-key', resourceToken)
module apiKeySecret './modules/security/keyvault-secret.bicep' = {
  name: 'secret-api-key${deploymentSuffix}'
  params: {
    keyVaultName: keyVault.outputs.name
    secretName: 'api-key'
    existingSecretNames: deduplicateKVSecrets ? keyVaultSecretList!.outputs.secretNameList : ''
    secretValue: apiKeyValue
  }
}

module apimSecret './modules/security/keyvault-secret.bicep' = {
  name: 'apim-search${deploymentSuffix}'
  params: {
    keyVaultName: keyVault.outputs.name
    secretName: 'apimkey'
    secretValue: apimAccessKey
    existingSecretNames: deduplicateKVSecrets ? keyVaultSecretList!.outputs.secretNameList : ''
  }
  dependsOn: [apim]
}

module entraClientIdSecret './modules/security/keyvault-secret.bicep' = if (deployEntraClientSecrets) {
  name: 'entraClientId-search${deploymentSuffix}'
  params: {
    keyVaultName: keyVault.outputs.name
    secretName: 'entraclientid'
    secretValue: entraClientId
    existingSecretNames: deduplicateKVSecrets ? keyVaultSecretList!.outputs.secretNameList : ''
  }
}
module entraClientSecretSecret './modules/security/keyvault-secret.bicep' = if (deployEntraClientSecrets) {
  name: 'entraClientSecret-search${deploymentSuffix}'
  params: {
    keyVaultName: keyVault.outputs.name
    secretName: 'entraclientsecret'
    secretValue: entraClientSecret
    existingSecretNames: deduplicateKVSecrets ? keyVaultSecretList!.outputs.secretNameList : ''
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
  params: {
    accountName: resourceNames.outputs.cosmosName
    databaseName: uiDatabaseName
    sessionsDatabaseName: sessionsDatabaseName
    sessionContainerArray: sessionsContainerArray
    containerArray: cosmosContainerArray
    location: location
    tags: tags
    privateEndpointSubnetId: vnet.outputs.subnetPeResourceID
    privateEndpointName: resourceNames.outputs.peCosmosDbName
    managedIdentityPrincipalId: identity.outputs.managedIdentityPrincipalId
    userPrincipalId: principalId
    publicNetworkAccess: publicAccessEnabled ? 'enabled' : 'disabled'
    myIpAddress: myIpAddress
    disableKeys: true
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- Search Service Resource ------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module searchService './modules/search/search-services.bicep' = {
  name: 'search${deploymentSuffix}'
  params: {
    disableLocalAuth: true
    location: location
    name: resourceNames.outputs.searchServiceName
    publicNetworkAccess: publicAccessEnabled ? 'enabled' : 'disabled'
    myIpAddress: myIpAddress
    privateEndpointSubnetId: vnet.outputs.subnetPeResourceID
    privateEndpointName: resourceNames.outputs.peSearchServiceName
    managedIdentityId: identity.outputs.managedIdentityId
    sku: {
      name: 'basic'
    }
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- Azure OpenAI/Foundry Resources ------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module aiFoundry './modules/ai/cognitive-services.bicep' = {
  name: 'aiFoundry${deploymentSuffix}'
  params: {
    managedIdentityId: identity.outputs.managedIdentityId
    name: resourceNames.outputs.cogServiceName
    location: location
    appInsightsName: logAnalytics.outputs.applicationInsightsName
    disableLocalAuth: true
    tags: tags
    deployments: [
      {
        name: 'text-embedding'
        properties: {
          model: {
            format: 'OpenAI'
            name: 'text-embedding-ada-002'
            version: '2'
          }
        }
      }
      {
        name: 'gpt-35-turbo'
        properties: {
          model: {
            format: 'OpenAI'
            name: 'gpt-35-turbo'
            version: '0125'
          }
        }
      }
      {
        name: gpt40_DeploymentName
        properties: {
          model: {
            format: 'OpenAI'
            name: gpt40_DeploymentName
            version: gpt40_ModelVersion
          }
        }
        sku: {
          name: 'Standard'
          capacity: gpt40_DeploymentCapacity
        }
      }
      {
        name: gpt41_DeploymentName
        properties: {
          model: {
            format: 'OpenAI'
            name: gpt41_DeploymentName
            version: gpt41_ModelVersion
          }
        }
        sku: {
          name: 'GlobalStandard'
          capacity: gpt41_DeploymentCapacity
        }
      }
    ]
    publicNetworkAccess: publicAccessEnabled ? 'enabled' : 'disabled'
    privateEndpointSubnetId: vnet.outputs.subnetPeResourceID
    agentSubnetId: vnet.outputs.subnetAgentResourceID
    privateEndpointName: resourceNames.outputs.peOpenAIName
    myIpAddress: myIpAddress
  }
  dependsOn: [
    searchService
  ]
}

module documentIntelligence './modules/ai/document-intelligence.bicep' = if (deployDocumentIntelligence) {
  name: 'doc-intelligence${deploymentSuffix}'
  params: {
    disableLocalAuth: true
    name: resourceNames.outputs.documentIntelligenceName
    location: location // this may be different than the other resources
    tags: tags
    publicNetworkAccess: publicAccessEnabled ? 'enabled' : 'disabled'
    privateEndpointSubnetId: vnet.outputs.subnetPeResourceID
    privateEndpointName: resourceNames.outputs.peDocumentIntelligenceName
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
// AI Project
var numberOfProjects int = 4 // This is the number of AI Projects to create
// deploying AI projects in sequence

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
  name: 'aiProject${deploymentSuffix}-1'
  params: {
    foundryName: aiFoundry.outputs.name
    location: location
    projectNo: 1
    aiDependencies: aiDependecies
  }
}

module aiProject2 './modules/ai/ai-project-with-caphost.bicep' = {
  name: 'aiProject${deploymentSuffix}-2'
  params: {
    foundryName: aiFoundry.outputs.name
    location: location
    projectNo: 2
    aiDependencies: aiDependecies
  }
  dependsOn: [
    aiProject1
  ]
}

module aiProject3 './modules/ai/ai-project-with-caphost.bicep' = {
  name: 'aiProject${deploymentSuffix}-3'
  params: {
    foundryName: aiFoundry.outputs.name
    location: location
    projectNo: 3
    aiDependencies: aiDependecies
  }
  dependsOn: [
    aiProject2
  ]
}

module aiProject4 './modules/ai/ai-project-with-caphost.bicep' = {
  name: 'aiProject${deploymentSuffix}-4'
  params: {
    foundryName: aiFoundry.outputs.name
    location: location
    projectNo: 4
    aiDependencies: aiDependecies
  }
dependsOn: [
    aiProject3
  ]
}

// --------------------------------------------------------------------------------------------------------------
// -- APIM ------------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module apim './modules/api-management/apim.bicep' = if (deployAPIM) {
  name: 'apim${deploymentSuffix}'
  params: {
    location: location
    name: resourceNames.outputs.apimName
    commonTags: tags
    publisherEmail: apimPublisherEmail
    publisherName: adminPublisherName
    appInsightsName: logAnalytics.outputs.applicationInsightsName
    subscriptionName: apimSubscriptionName
  }
}

module apimConfiguration './modules/api-management/apim-oai-config.bicep' = if (deployAPIM) {
  name: 'apimConfig${deploymentSuffix}'
  params: {
    apimName: apim!.outputs.name
    apimLoggerName: apim!.outputs.loggerName
    cognitiveServicesName: aiFoundry.outputs.name
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- DNS ZONES ---------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module allDnsZones './modules/networking/all-zones.bicep' = if (createDnsZones) {
  name: 'all-dns-zones${deploymentSuffix}'
  params: {
    tags: tags
    vnetResourceId: vnet.outputs.vnetResourceId

    keyVaultPrivateEndpointName: keyVault.outputs.privateEndpointName
    openAiPrivateEndpointName: aiFoundry.outputs.privateEndpointName
    aiSearchPrivateEndpointName: searchService.outputs.privateEndpointName
    storageBlobPrivateEndpointName: storage.outputs.privateEndpointBlobName
    storageQueuePrivateEndpointName: storage.outputs.privateEndpointQueueName
    storageTablePrivateEndpointName: storage.outputs.privateEndpointTableName

    documentIntelligencePrivateEndpointName: deployDocumentIntelligence
      ? documentIntelligence!.outputs.privateEndpointName
      : ''
    acrPrivateEndpointName: deployContainerRegistry ? containerRegistry!.outputs.privateEndpointName : ''

    //commenting as we are not deploying the managed environment in the LZ
    cosmosPrivateEndpointName: cosmos.outputs.privateEndpointName
    defaultAcaDomain: deployCAEnvironment ? managedEnvironment!.outputs.defaultDomain : null
    acaStaticIp: deployCAEnvironment ? managedEnvironment!.outputs.staticIp : null
    acaPrivateEndpointName: deployCAEnvironment ? managedEnvironment!.outputs.privateEndpointName : null
  }
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
    subnetId: vnet.outputs.subnetBastionResourceID // Make sure this output exists in your vnet module
    tags: tags
    enableTunneling: true
    enableFileCopy: true
    skuName: 'Standard'
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- Application Gateway --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------

// Deploy WAF Policy for Application Gateway
module appGatewayWafPolicy './modules/networking/application-gateway-waf-policy.bicep' = if (deployApplicationGateway && deployCAEnvironment) {
  name: 'appGatewayWafPolicy${deploymentSuffix}'
  params: {
    name: resourceNames.outputs.appGatewayWafPolicyName
    location: location
    tags: tags
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
          ruleGroupOverrides: []
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.0'
        }
      ]
      exclusions: []
    }
    policySettings: {
      state: 'Enabled'
      mode: 'Prevention'
      requestBodyCheck: true
      requestBodyInspectLimitInKB: 128
      requestBodyEnforcement: true
      maxRequestBodySizeInKb: 128
      fileUploadEnforcement: true
      fileUploadLimitInMb: 100
      customBlockResponseStatusCode: 403
      customBlockResponseBody: 'VGhpcyByZXF1ZXN0IGhhcyBiZWVuIGJsb2NrZWQgYnkgdGhlIFdlYiBBcHBsaWNhdGlvbiBGaXJld2FsbC4='
    }
  }
}

// Deploy Public IP for Application Gateway
module appGatewayPublicIp './modules/networking/public-ip.bicep' = if (deployApplicationGateway && deployCAEnvironment) {
  name: 'appGatewayPublicIp${deploymentSuffix}'
  params: {
    name: resourceNames.outputs.appGatewayPublicIpName
    location: location
    tags: tags
    allocationMethod: 'Static'
    sku: 'Standard'
    tier: 'Regional'
    dnsLabelPrefix: !empty(appGatewayDnsLabelPrefix)
      ? appGatewayDnsLabelPrefix
      : '${toLower(resourceNames.outputs.appGatewayName)}-${resourceToken}'
    zones: [1, 2, 3]
  }
}

// Deploy Application Gateway
module applicationGateway './modules/networking/application-gateway.bicep' = if (deployApplicationGateway && deployCAEnvironment) {
  name: 'applicationGateway${deploymentSuffix}'
  params: {
    name: resourceNames.outputs.appGatewayName
    location: location
    tags: tags
    sku: appGatewaySkuName
    autoscaleMinCapacity: appGatewayMinCapacity
    autoscaleMaxCapacity: appGatewayMaxCapacity
    enableHttp2: appGatewayEnableHttp2
    enableFips: appGatewayEnableFips
    zones: appGatewayPublicIp!.outputs.availabilityZones

    // WAF Policy association
    firewallPolicyResourceId: appGatewayWafPolicy!.outputs.resourceId

    // Gateway IP Configuration (subnet association)
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: vnet.outputs.subnetAppGwResourceID
          }
        }
      }
    ]

    // Frontend IP Configuration (public IP association)
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: appGatewayPublicIp!.outputs.resourceId
          }
        }
      }
    ]

    // Frontend Ports
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
    ]

    // Backend Address Pools
    backendAddressPools: [
      {
        name: 'appServiceBackendPool'
        properties: {
          backendAddresses: appGatewayBackendAddresses
        }
      }
    ]

    // Backend HTTP Settings
    backendHttpSettingsCollection: [
      {
        name: 'appServiceBackendHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 20
          connectionDraining: {
            enabled: true
            drainTimeoutInSec: 60
          }
        }
      }
      {
        name: 'appServiceBackendHttpsSettings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 20
          connectionDraining: {
            enabled: true
            drainTimeoutInSec: 60
          }
        }
      }
    ]

    // HTTP Listeners
    httpListeners: [
      {
        name: 'appServiceHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendIPConfigurations',
              resourceNames.outputs.appGatewayName,
              'appGatewayFrontendIP'
            )
          }
          frontendPort: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendPorts',
              resourceNames.outputs.appGatewayName,
              'port_80'
            )
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
    ]

    // Request Routing Rules
    requestRoutingRules: [
      {
        name: 'appServiceRule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/httpListeners',
              resourceNames.outputs.appGatewayName,
              'appServiceHttpListener'
            )
          }
          backendAddressPool: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendAddressPools',
              resourceNames.outputs.appGatewayName,
              'appServiceBackendPool'
            )
          }
          backendHttpSettings: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
              resourceNames.outputs.appGatewayName,
              'appServiceBackendHttpSettings'
            )
          }
        }
      }
    ]

    // SSL Certificates (if provided)
    sslCertificates: !empty(appGatewaySslCertificateKeyVaultSecretId)
      ? [
          {
            name: 'appGatewaySslCert'
            properties: {
              keyVaultSecretId: appGatewaySslCertificateKeyVaultSecretId
            }
          }
        ]
      : []

    // Managed Identity for Key Vault access
    managedIdentities: {
      userAssignedResourceIds: [
        identity.outputs.managedIdentityId
      ]
    }

    // Diagnostic Settings for monitoring
    diagnosticSettings: [
      {
        name: 'appGateway-diagnostics'
        workspaceResourceId: logAnalytics.outputs.logAnalyticsWorkspaceId
        storageAccountResourceId: storage.outputs.id
        metricCategories: [
          {
            category: 'AllMetrics'
            enabled: true
          }
        ]
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
            enabled: true
          }
        ]
      }
    ]
  }
  dependsOn: []
}

// --------------------------------------------------------------------------------------------------------------
// -- Container App Environment ---------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module managedEnvironment './modules/app/managedEnvironment.bicep' = if (deployCAEnvironment) {
  name: 'caenv${deploymentSuffix}'
  params: {
    newEnvironmentName: resourceNames.outputs.caManagedEnvName
    location: location
    logAnalyticsWorkspaceName: logAnalytics.outputs.logAnalyticsWorkspaceName
    logAnalyticsRgName: resourceGroupName
    appSubnetId: vnet.outputs.subnetAppSeResourceID
    tags: tags
    publicAccessEnabled: publicAccessEnabled
    containerAppEnvironmentWorkloadProfiles: containerAppEnvironmentWorkloadProfiles
    privateEndpointName: resourceNames.outputs.peContainerAppsName
    privateEndpointSubnetId: vnet.outputs.subnetPeResourceID
  }
}

var apiTargetPort = 8000
var apiSettings = [
  {
    name: 'API_URL'
    value: deployCAEnvironment
      ? 'https://${resourceNames.outputs.containerAppAPIName}.${managedEnvironment!.outputs.defaultDomain}/agent'
      : ''
  }
  { name: 'API_KEY', secretRef: 'apikey' }
  { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', value: logAnalytics.outputs.appInsightsConnectionString }

  { name: 'SEMANTICKERNEL_EXPERIMENTAL_GENAI_ENABLE_OTEL_DIAGNOSTICS', value: 'true' }
  { name: 'SEMANTICKERNEL_EXPERIMENTAL_GENAI_ENABLE_OTEL_DIAGNOSTICS_SENSITIVE', value: 'true' }

  { name: 'AZURE_AI_AGENT_ENDPOINT', value: aiProject1.outputs.foundry_connection_string }
  { name: 'AZURE_AI_AGENT_MODEL_DEPLOYMENT_NAME', value: gpt41_DeploymentName }

  { name: 'COSMOS_DB_ENDPOINT', value: cosmos.outputs.endpoint }
  { name: 'COSMOS_DB_API_SESSIONS_DATABASE_NAME', value: sessionsDatabaseName }
  { name: 'COSMOS_DB_API_SESSIONS_CONTAINER_NAME', value: sessionsContainerArray[0].name }

  { name: 'AZURE_CLIENT_ID', value: identity.outputs.managedIdentityClientId }

  { name: 'AZURE_SDK_TRACING_IMPLEMENTATION', value: 'opentelemetry' }
  { name: 'AZURE_TRACING_GEN_AI_CONTENT_RECORDING_ENABLED', value: 'true' }

  { name: 'APIM_BASE_URL', value: apimBaseUrl }
  { name: 'APIM_ACCESS_URL', value: apimAccessUrl }
  { name: 'APIM_KEY', secretRef: 'apimkey' }
  { name: 'MOCK_USER_UPN', value: string(mockUserUpn) }
]
var apimSettings = deployAPIM
  ? [
  { name: 'API_MANAGEMENT_NAME', value: apim!.outputs.name }
  { name: 'API_MANAGEMENT_ID', value: apim!.outputs.id }
  { name: 'API_MANAGEMENT_ENDPOINT', value: apim!.outputs.gatewayUrl }
    ]
  : []
var entraSecuritySettings = deployEntraClientSecrets
  ? [
  { name: 'ENTRA_TENANT_ID', value: entraTenantId }
  { name: 'ENTRA_API_AUDIENCE', value: entraApiAudience }
  { name: 'ENTRA_SCOPES', value: entraScopes }
      {
        name: 'ENTRA_REDIRECT_URI'
        value: entraRedirectUri ?? 'https://${resourceNames.outputs.containerAppUIName}.${managedEnvironment!.outputs.defaultDomain}/auth/callback'
      }
  { name: 'ENTRA_CLIENT_ID', secretRef: 'entraclientid' }
  { name: 'ENTRA_CLIENT_SECRET', secretRef: 'entraclientsecret' }
    ]
  : []

var baseSecretSet = {
  apikey: apiKeySecret.outputs.secretUri
}
var apimSecretSet = empty(apimAccessKey)
  ? {}
  : {
  apimkey: apimSecret!.outputs.secretUri
}
var entraSecretSet = deployEntraClientSecrets
  ? {
  entraclientid: entraClientIdSecret!.outputs.secretUri
  entraclientsecret: entraClientSecretSecret!.outputs.secretUri
    }
  : {}

module containerAppAPI './modules/app/containerappstub.bicep' = if (deployAPIApp) {
  name: 'ca-api-stub${deploymentSuffix}'
  params: {
    appName: resourceNames.outputs.containerAppAPIName
    managedEnvironmentName: managedEnvironment!.outputs.name
    managedEnvironmentRg: managedEnvironment!.outputs.resourceGroupName
    workloadProfileName: appContainerAppEnvironmentWorkloadProfileName
    registryName: resourceNames.outputs.ACR_Name
    targetPort: apiTargetPort
    userAssignedIdentityName: identity.outputs.managedIdentityName
    location: location
    imageName: apiImageName
    
    tags: union(tags, { 'azd-service-name': 'api' })
    secrets: union(baseSecretSet, apimSecretSet, entraSecretSet) 
    env: union(apiSettings, apimSettings, entraSecuritySettings)
  }
  dependsOn: createDnsZones && deployContainerRegistry
    ? [allDnsZones, containerRegistry, apim]
    : (createDnsZones && !deployContainerRegistry)
        ? [allDnsZones, apim]
        : (!createDnsZones && deployContainerRegistry) ? [containerRegistry, apim] : [apim]
}

var UITargetPort = 8001
var UISettings = union(apiSettings, [
  {
    name: 'API_URL'
    value: deployCAEnvironment
      ? 'https://${resourceNames.outputs.containerAppAPIName}.${managedEnvironment!.outputs.defaultDomain}/agent'
      : ''
  }
])

module containerAppUI './modules/app/containerappstub.bicep' = if (deployUIApp) {
  name: 'ca-UI-stub${deploymentSuffix}'
  params: {
    appName: resourceNames.outputs.containerAppUIName
    managedEnvironmentName: managedEnvironment!.outputs.name
    managedEnvironmentRg: managedEnvironment!.outputs.resourceGroupName
    workloadProfileName: appContainerAppEnvironmentWorkloadProfileName
    registryName: resourceNames.outputs.ACR_Name
    targetPort: UITargetPort
    userAssignedIdentityName: identity.outputs.managedIdentityName
    location: location
    imageName: uiImageName
    tags: union(tags, { 'azd-service-name': 'UI' })
    secrets: union(baseSecretSet, apimSecretSet, entraSecretSet)
    env: union(UISettings, apimSettings, entraSecuritySettings)
  }
  dependsOn: createDnsZones && deployContainerRegistry
    ? [allDnsZones, containerRegistry, apim]
    : (createDnsZones && !deployContainerRegistry)
        ? [allDnsZones, apim]
        : (!createDnsZones && deployContainerRegistry) ? [containerRegistry, apim] : [apim]
}

// --------------------------------------------------------------------------------------------------------------
// -- Outputs ---------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
output SUBSCRIPTION_ID string = subscription().subscriptionId
output ACR_NAME string = deployContainerRegistry ? containerRegistry!.outputs.name : ''
output ACR_URL string = deployContainerRegistry ? containerRegistry!.outputs.loginServer : ''
output AI_ENDPOINT string = aiFoundry.outputs.endpoint
output AI_FOUNDRY_PROJECT_ID string = aiProject1.outputs.projectId
output AI_FOUNDRY_PROJECT_NAME string = aiProject1.outputs.projectName
output AI_PROJECT_NAME string = resourceNames.outputs.aiHubProjectName
output AI_SEARCH_ENDPOINT string = searchService.outputs.endpoint
output API_CONTAINER_APP_FQDN string = deployAPIApp ? containerAppAPI!.outputs.fqdn : ''
output API_CONTAINER_APP_NAME string = deployAPIApp ? containerAppAPI!.outputs.name : ''
output UI_CONTAINER_APP_FQDN string = deployUIApp ? containerAppUI!.outputs.fqdn : ''
output UI_CONTAINER_APP_NAME string = deployUIApp ? containerAppUI!.outputs.name : ''
output API_KEY string = apiKeyValue
output API_MANAGEMENT_ID string = deployAPIM ? apim!.outputs.id : ''
output API_MANAGEMENT_NAME string = deployAPIM ? apim!.outputs.name : ''
output AZURE_CONTAINER_ENVIRONMENT_NAME string = deployCAEnvironment ? managedEnvironment!.outputs.name : ''
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = deployContainerRegistry ? containerRegistry!.outputs.loginServer : ''
output AZURE_CONTAINER_REGISTRY_NAME string = deployContainerRegistry ? containerRegistry!.outputs.name : ''
output AZURE_RESOURCE_GROUP string = resourceGroupName
output COSMOS_CONTAINER_NAME string = uiChatContainerName
output COSMOS_DATABASE_NAME string = cosmos.outputs.databaseName
output COSMOS_ENDPOINT string = cosmos.outputs.endpoint
output DOCUMENT_INTELLIGENCE_ENDPOINT string = deployDocumentIntelligence ? documentIntelligence!.outputs.endpoint : ''
output MANAGED_ENVIRONMENT_ID string = deployCAEnvironment ? managedEnvironment!.outputs.id : ''
output MANAGED_ENVIRONMENT_NAME string = deployCAEnvironment ? managedEnvironment!.outputs.name : ''
output RESOURCE_TOKEN string = resourceToken
output STORAGE_ACCOUNT_BATCH_IN_CONTAINER string = storage.outputs.containerNames[1].name
output STORAGE_ACCOUNT_BATCH_OUT_CONTAINER string = storage.outputs.containerNames[2].name
output STORAGE_ACCOUNT_CONTAINER string = storage.outputs.containerNames[0].name
output STORAGE_ACCOUNT_NAME string = storage.outputs.name

output VNET_CORE_ID string = vnet.outputs.vnetResourceId
output VNET_CORE_NAME string = vnet.outputs.vnetName
output VNET_CORE_PREFIX string = vnet.outputs.vnetAddressPrefix

// Virtual Machine outputs (if deployed)
output VM_ID string = deployVirtualMachine ? virtualMachine!.outputs.vm_id : ''
output VM_PRIVATE_IP string = deployVirtualMachine ? virtualMachine!.outputs.vm_private_ip : ''
output VM_PUBLIC_IP string = deployVirtualMachine ? virtualMachine!.outputs.vm_public_ip : ''

// Application Gateway outputs (if deployed)
output APPLICATION_GATEWAY_ID string = deployApplicationGateway && deployCAEnvironment
  ? applicationGateway!.outputs.resourceId
  : ''
output APPLICATION_GATEWAY_NAME string = deployApplicationGateway && deployCAEnvironment
  ? applicationGateway!.outputs.name
  : ''
output APPLICATION_GATEWAY_PUBLIC_IP string = deployApplicationGateway && deployCAEnvironment
  ? appGatewayPublicIp!.outputs.ipAddress
  : ''
output APPLICATION_GATEWAY_FQDN string = deployApplicationGateway && deployCAEnvironment
  ? appGatewayPublicIp!.outputs.fqdn
  : ''
output APPLICATION_GATEWAY_WAF_POLICY_ID string = deployApplicationGateway && deployCAEnvironment
  ? appGatewayWafPolicy!.outputs.resourceId
  : ''
