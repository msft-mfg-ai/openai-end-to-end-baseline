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
//param azdEnvName string = ''

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
param admin_username string = 'fewald'
@secure()
@description('Admin password for the VM (optional - only deploy VM if provided)')
param admin_password string = 'P@ssw0rd123!' // This is a default password, you should change it to something more secure
@description('VM name (optional - only deploy VM if provided)')
param vm_name string ='jumpbox-vm'

// --------------------------------------------------------------------------------------------------------------
// Container App Environment
// --------------------------------------------------------------------------------------------------------------
//Commenting container app environment as we are not deploying it in the LZ
// @description('Name of the Container Apps Environment workload profile to use for the app')
// param appContainerAppEnvironmentWorkloadProfileName string = 'app'
// @description('Workload profiles for the Container Apps environment')
// param containerAppEnvironmentWorkloadProfiles array = [
//   {
//     name: 'app'
//     workloadProfileType: 'D4'
//     minimumCount: 1
//     maximumCount: 10
//   }
// ]

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
// AI Models
// --------------------------------------------------------------------------------------------------------------
@description('The default GPT 4o model deployment name for the AI Agent')
param gpt40_DeploymentName string = 'gpt-4o' 
@description('The GPT 4o model version to use')
param gpt40_ModelVersion string = '2024-11-20'
@description('The GPT 4o model deployment capacity')
param gpt40_DeploymentCapacity int = 10

@description('The default GPT 4.1 model deployment name for the AI Agent')
param gpt41_DeploymentName string = 'gpt-4o-mini'
@description('The GPT 4.1 model version to use')
param gpt41_ModelVersion string = '2024-07-18'
@description('The GPT 4.1 model deployment capacity')
param gpt41_DeploymentCapacity int = 10

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
// External APIM Parameters
// --------------------------------------------------------------------------------------------------------------
//@description('Base URL to facade API')
//param apimBaseUrl string = ''
//param apimAccessUrl string = ''
//@secure()
//param apimAccessKey string = ''

// --------------------------------------------------------------------------------------------------------------
// Existing images
// --------------------------------------------------------------------------------------------------------------
//param apiImageName string = ''
//param UIImageName string = ''

// --------------------------------------------------------------------------------------------------------------
// Other deployment switches  
// --------------------------------------------------------------------------------------------------------------
@description('Should resources be created with public access?')
param publicAccessEnabled bool = true
@description('Create DNS Zones?')
param createDnsZones bool = true
// commented out as roleassigments should be part of the application deployment not the LZ
@description('Add Role Assignments for the user assigned identity?')
param addRoleAssignments bool = true
@description('Should we run a script to dedupe the KeyVault secrets? (this fails on private networks right now)')
param deduplicateKeyVaultSecrets bool = false
@description('Set this if you want to append all the resource names with a unique token')
param appendResourceTokens bool = false

//comented as we are not using container app
//@description('Should API container app be deployed?')
//param deployAPIApp bool = false
//@description('Should UI container app be deployed?')
//param deployUIApp bool = false

@description('Global Region where the resources will be deployed, e.g. AM (America), EM (EMEA), AP (APAC), CH (China)')
//@allowed(['AM', 'EM', 'AP', 'CH', 'NAA'])
param regionCode string = ''

@description('Instance number for the application, e.g. 001, 002, etc. This is used to differentiate multiple instances of the same application in the same environment.')
param instanceNumber string = '001' // used to differentiate multiple instances of the same application in the same environment

// // --------------------------------------------------------------------------------------------------------------
// // Additional Tags that may be included or not
// // --------------------------------------------------------------------------------------------------------------
//param costCenterTag string = ''
//param ownerEmailTag string = ''
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

var tags = {
  'creation-date': take(runDateTime, 8)
  'application-name':  'otisone-ooai'
  'application-id':    'not-applicable'
  'application-owner': 'sanjithraj.rao_otis.com'
  'business-owner':    'sanjithraj.rao_otis.com'
  'cost-center':       '90090143'
  'created-by':        'pavan.gajavalli_otis.com'
  'environment-name':  'dev'
  'lti-service-class': 'bronge'
  'otis-region':       'amer'
  'primary-support-provider': 'ltim'
  'request-number':    'not-applicable'
  'requestor-name':    'daniel.pahng_otis.com'
}
//var commonTags = tags

// var commonTags = {
//   'creation-date': take(runDateTime, 8)
//   'application-name': appName
//   'application-id': applicationId
//   'environment-name': environmentName
//   'global-region': regionCode
//   'requestor-name': requestorName
//   'primary-support-provider': primarySupportProviderTag == '' ? 'UNKNOWN' : primarySupportProviderTag
// }

var commonTags = {
  'creation-date': take(runDateTime, 8)
  'application-name': appName
  'application-id': applicationId
  'environment-name': environmentName
  'global-region': regionCode
  'requestor-name': requestorName
  'primary-support-provider': primarySupportProviderTag == '' ? 'UNKNOWN' : primarySupportProviderTag
}
//var costCenterTagObject = costCenterTag == '' ? {} : { 'cost-center': costCenterTag }
//var ownerEmailTagObject = ownerEmailTag == ''
//  ? {}
//  : {
//  'application-owner': ownerEmailTag
//  'business-owner': ownerEmailTag
//  'point-of-contact': ownerEmailTag
//}
// if this bicep was called from AZD, then it needs this tag added to the resource group (at a minimum) to deploy successfully...
//var azdTag = azdEnvName != '' ? { 'azd-env-name': azdEnvName } : {}
//var tags = union(commonTags, azdTag, costCenterTagObject, ownerEmailTagObject)

// Run a script to dedupe the KeyVault secrets -- this fails on private networks right now so turn if off for them
var deduplicateKVSecrets = publicAccessEnabled ? deduplicateKeyVaultSecrets : false

var vnetAddressPrefix = vnetPrefix

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
module vnet './modules/networking/vnet.bicep' = {
  name: 'vnet${deploymentSuffix}'
  params: {
    location: location
    existingVirtualNetworkName: existingVnetName
    existingVnetResourceGroupName: existingVnetResourceGroupName
    newVirtualNetworkName: resourceNames.outputs.vnet_Name
    vnetAddressPrefix: vnetAddressPrefix
    vnetNsgName: resourceNames.outputs.vnetNsgName
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
//commented as should be part of the app deployment not the LZ

module containerRegistry './modules/app/containerregistry.bicep' = {
  name: 'containerregistry${deploymentSuffix}'
  params: {
   newRegistryName: resourceNames.outputs.ACR_Name
   location: location
   acrSku: 'Premium'
   tags: tags
   publicAccessEnabled: publicAccessEnabled
   privateEndpointName: 'pe-${resourceNames.outputs.ACR_Name}'
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
    keyVaultName: keyVault.outputs.name
    apimName: deployAPIM ? apim.outputs.name : ''
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
    keyVaultName: keyVault.outputs.name
    apimName: deployAPIM ? apim.outputs.name : ''
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

//commented as we are not deploying document intelligence in the LZ
// module documentIntelligenceSecret './modules/security/keyvault-cognitive-secret.bicep' = {
//   name: 'secret-doc-intelligence${deploymentSuffix}'
//   params: {
//     keyVaultName: keyVault.outputs.name
//     secretName: documentIntelligence.outputs.keyVaultSecretName
//     cognitiveServiceName: documentIntelligence.outputs.name
//     cognitiveServiceResourceGroup: documentIntelligence.outputs.resourceGroupName
//     existingSecretNames: deduplicateKVSecrets ? keyVaultSecretList.outputs.secretNameList : ''
//   }
// }

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
var sessionsDatabaseName = 'Sessions'
var uiChatContainerName = 'ChatTurn'
var uiChatContainerName2 = 'ChatHistory'
var apiSessionsContainerName = 'apisessions'
var sessionsContainerName = 'sessions'
var cosmosContainerArray = [
  { name: 'AgentLog', partitionKey: '/requestId' }
  { name: 'UserDocuments', partitionKey: '/userId' }
  { name: uiChatContainerName, partitionKey: '/chatId' }
  { name: uiChatContainerName2, partitionKey: '/chatId' }
]
var sessionsContainerArray = [
  { name: apiSessionsContainerName, partitionKey: '/id' }
  { name: sessionsContainerName, partitionKey: '/id' }
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
    privateEndpointSubnetId: vnet.outputs.subnetPeResourceID
    privateEndpointName: resourceNames.outputs.peSearchServiceName
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
    textEmbeddings: [
      {
      name: 'text-embedding'
      model: {
        format: 'OpenAI'
        name: 'text-embedding-ada-002'
        version: '2'
      }
      }
    ]
    chatGpt_Standard: {
      DeploymentName: 'gpt-35-turbo'
      ModelName: 'gpt-35-turbo'
      ModelVersion: '0125'
      DeploymentCapacity: 10
    }
    chatGpt_Premium: {
      DeploymentName: gpt40_DeploymentName
      ModelName: gpt40_DeploymentName
      ModelVersion: gpt40_ModelVersion
      DeploymentCapacity: gpt40_DeploymentCapacity

    }
    chatGpt_41: {
      DeploymentName: gpt41_DeploymentName
      ModelName: gpt41_DeploymentName
      ModelVersion: gpt41_ModelVersion
      DeploymentCapacity: gpt41_DeploymentCapacity
    }
    publicNetworkAccess: publicAccessEnabled ? 'enabled' : 'disabled'
    privateEndpointSubnetId: vnet.outputs.subnetPeResourceID
    privateEndpointName: resourceNames.outputs.peOpenAIName
    peOpenAIServiceConnection: resourceNames.outputs.peOpenAIServiceConnection
    myIpAddress: myIpAddress
  }
  dependsOn: [
    searchService
  ]
}

//commenting documment intelligence as it is part of the application not lz

// module documentIntelligence './modules/ai/document-intelligence.bicep' = {
//   name: 'doc-intelligence${deploymentSuffix}'
//   params: {
//     name: resourceNames.outputs.documentIntelligenceName
//     location: location // this may be different than the other resources
//     tags: tags
//     publicNetworkAccess: publicAccessEnabled ? 'enabled' : 'disabled'
//     privateEndpointSubnetId: vnet.outputs.subnetPeResourceID
//     privateEndpointName: 'pe-${resourceNames.outputs.documentIntelligenceName}'
//     myIpAddress: myIpAddress
//     managedIdentityId: identity.outputs.managedIdentityId
//   }
//   dependsOn: [
//     searchService
//   ]
// }

// --------------------------------------------------------------------------------------------------------------
// AI Foundry Hub and Project V2
// Imported from https://github.com/adamhockemeyer/ai-agent-experience
// --------------------------------------------------------------------------------------------------------------
module aiFoundryHub './modules/ai-foundry/ai-foundry-hub.bicep' = {
  name: 'aiHub${deploymentSuffix}'
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
    //appInsightsName: logAnalytics.outputs.applicationInsightsName
    //appInsightsResourceGroupName: resourceGroup().name
    //appInsightsSubscriptionId: subscription().subscriptionId
  }
}

module formatProjectWorkspaceId './modules/cognitive-services/format-project-workspace-id.bicep' = {
  name: 'aiProjectFormatWorkspaceId${deploymentSuffix}'
  params: {
    projectWorkspaceId: aiProject.outputs.projectWorkspaceId
  }
}

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

// --------------------------------------------------------------------------------------------------------------
// -- DNS ZONES ---------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module allDnsZones './modules/networking/all-zones.bicep' = if (createDnsZones) {
  name: 'all-dns-zones${deploymentSuffix}'
  params: {
    tags: tags
    vnetResourceId: vnet.outputs.vnetResourceId

    keyVaultPrivateEndpointName: keyVault.outputs.privateEndpointName
    //commenting below as we are not deploying container registry in the LZ - if uncommented need go to /modules/networking/all-zones.bicep and uncomment the acrPrivateEndpointName parameter
    //acrPrivateEndpointName: containerRegistry.outputs.privateEndpointName
    openAiPrivateEndpointName: openAI.outputs.privateEndpointName
    aiSearchPrivateEndpointName: searchService.outputs.privateEndpointName
    //commenting document intelligence as it is part of the application not the LZ -if uncommented need to go to /modules/networking/all-zones.bicep and uncomment the documentIntelligencePrivateEndpointName parameter
    //documentIntelligencePrivateEndpointName: documentIntelligence.outputs.privateEndpointName
    //commenting cosmos as it is part of the application not the LZ - if uncommented need to go to /modules/networking/all-zones.bicep and uncomment the cosmosPrivateEndpointName parameter
    //cosmosPrivateEndpointName: cosmos.outputs.privateEndpointName
    storageBlobPrivateEndpointName: storage.outputs.privateEndpointBlobName
    storageQueuePrivateEndpointName: storage.outputs.privateEndpointQueueName
    storageTablePrivateEndpointName: storage.outputs.privateEndpointTableName

    //commenting as we are not deploying the maanged environment in the LZ
    //defaultAcaDomain: managedEnvironment.outputs.defaultDomain
    //acaStaticIp: managedEnvironment.outputs.staticIp
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
    subnetId: vnet.outputs.subnetBastionResourceID  // Make sure this output exists in your vnet module
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
module appGatewayWafPolicy './modules/networking/application-gateway-waf-policy.bicep' = if (deployApplicationGateway) {
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
module appGatewayPublicIp './modules/networking/public-ip.bicep' = if (deployApplicationGateway) {
  name: 'appGatewayPublicIp${deploymentSuffix}'
  params: {
    name: resourceNames.outputs.appGatewayPublicIpName
    location: location
    tags: tags
    allocationMethod: 'Static'
    sku: 'Standard'
    tier: 'Regional'
    dnsLabelPrefix: !empty(appGatewayDnsLabelPrefix) ? appGatewayDnsLabelPrefix : '${toLower(resourceNames.outputs.appGatewayName)}-${resourceToken}'
    zones: [1, 2, 3]
  }
}

// Deploy Application Gateway
module applicationGateway './modules/networking/application-gateway.bicep' = if (deployApplicationGateway) {
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
    zones: [1, 2, 3]
    
    // WAF Policy association
    firewallPolicyResourceId: appGatewayWafPolicy.outputs.resourceId
    
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
            id: appGatewayPublicIp.outputs.resourceId
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
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', resourceNames.outputs.appGatewayName, 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', resourceNames.outputs.appGatewayName, 'port_80')
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
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', resourceNames.outputs.appGatewayName, 'appServiceHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', resourceNames.outputs.appGatewayName, 'appServiceBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', resourceNames.outputs.appGatewayName, 'appServiceBackendHttpSettings')
          }
        }
      }
    ]
    
    // SSL Certificates (if provided)
    sslCertificates: !empty(appGatewaySslCertificateKeyVaultSecretId) ? [
      {
        name: 'appGatewaySslCert'
        properties: {
          keyVaultSecretId: appGatewaySslCertificateKeyVaultSecretId
        }
      }
    ] : []
    
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
  dependsOn: [
  ]
}

// --------------------------------------------------------------------------------------------------------------
// -- Outputs ---------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
output SUBSCRIPTION_ID string = subscription().subscriptionId
// commenting as container registry is not part of the LZ deployment
//output ACR_NAME string = containerRegistry.outputs.name
//output ACR_URL string = containerRegistry.outputs.loginServer
output AI_ENDPOINT string = openAI.outputs.endpoint
output AI_HUB_ID string = deployAIHub ? aiFoundryHub.outputs.id : ''
output AI_HUB_NAME string = deployAIHub ? aiFoundryHub.outputs.name : ''
output AI_PROJECT_NAME string = resourceNames.outputs.aiHubProjectName
output AI_SEARCH_ENDPOINT string = searchService.outputs.endpoint
//commented as container app is not deployed in the LZ
//output API_CONTAINER_APP_FQDN string = deployAPIApp ? containerAppAPI.outputs.fqdn : ''
//output API_CONTAINER_APP_NAME string = deployAPIApp ? containerAppAPI.outputs.name : ''
output API_KEY string = apiKeyValue
output API_MANAGEMENT_ID string = deployAPIM ? apim.outputs.id : ''
output API_MANAGEMENT_NAME string = deployAPIM ? apim.outputs.name : ''
//commented as container app is not deployed in the LZ
//output AZURE_CONTAINER_ENVIRONMENT_NAME string = managedEnvironment.outputs.name
//output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
//output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
output AZURE_RESOURCE_GROUP string = resourceGroupName
////commented as Cosmos app is not deployed in the LZ
//output COSMOS_CONTAINER_NAME string = uiChatContainerName
//output COSMOS_DATABASE_NAME string = cosmos.outputs.databaseName
//output COSMOS_ENDPOINT string = cosmos.outputs.endpoint
//commented as Document Intelligence is not deployed in the LZ
//output DOCUMENT_INTELLIGENCE_ENDPOINT string = documentIntelligence.outputs.endpoint
//output MANAGED_ENVIRONMENT_ID string = managedEnvironment.outputs.id
//output MANAGED_ENVIRONMENT_NAME string = managedEnvironment.outputs.name
output RESOURCE_TOKEN string = resourceToken
output STORAGE_ACCOUNT_BATCH_IN_CONTAINER string = storage.outputs.containerNames[1].name
output STORAGE_ACCOUNT_BATCH_OUT_CONTAINER string = storage.outputs.containerNames[2].name
output STORAGE_ACCOUNT_CONTAINER string = storage.outputs.containerNames[0].name
output STORAGE_ACCOUNT_NAME string = storage.outputs.name
output VNET_CORE_ID string = vnet.outputs.vnetResourceId
output VNET_CORE_NAME string = vnet.outputs.vnetName
output VNET_CORE_PREFIX string = vnet.outputs.vnetAddressPrefix

// Virtual Machine outputs (if deployed)
output VM_ID string = (!empty(admin_username) && !empty(vm_name)) ? virtualMachine.outputs.vm_id : ''
output VM_PRIVATE_IP string = (!empty(admin_username) && !empty(vm_name)) ? virtualMachine.outputs.vm_private_ip : ''
output VM_PUBLIC_IP string = (!empty(admin_username) && !empty(vm_name)) ? virtualMachine.outputs.vm_public_ip : ''

// Application Gateway outputs (if deployed)
output APPLICATION_GATEWAY_ID string = deployApplicationGateway ? applicationGateway.outputs.resourceId : ''
output APPLICATION_GATEWAY_NAME string = deployApplicationGateway ? applicationGateway.outputs.name : ''
output APPLICATION_GATEWAY_PUBLIC_IP string = deployApplicationGateway ? appGatewayPublicIp.outputs.ipAddress : ''
output APPLICATION_GATEWAY_FQDN string = deployApplicationGateway ? appGatewayPublicIp.outputs.fqdn : ''
output APPLICATION_GATEWAY_WAF_POLICY_ID string = deployApplicationGateway ? appGatewayWafPolicy.outputs.resourceId : ''
