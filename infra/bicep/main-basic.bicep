// --------------------------------------------------------------------------------------------------------------
// Main bicep file that deploys a basic version of the LZ with
//   Public Endpoints, includes EVERYTHING for the application,
//   with optional parameters for existing resources.
// --------------------------------------------------------------------------------------------------------------
// You can test before deploy it with this command (run these commands in the same directory as this bicep file):
//   az deployment group what-if --resource-group rg_mfg-ai-lz --template-file 'main-basic.bicep' --parameters environmentName=dev applicationName=otaiexp applicationId=otaiexp1 instanceNumber=002 regionCode=naa
// You can deploy it with this command:
//   az deployment group create -n manual --resource-group rg_mfg-ai-lz --template-file 'main-basic.bicep' --parameters environmentName=dev applicationName=otaiexp applicationId=otaiexp1 instanceNumber=002 regionCode=naa
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
// @description('Environment name used by the azd command (optional)')
// param azdEnvName string = ''

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
// Container App Entra Parameters
// -------------------------------------------------------------------------------------------------------------`
param entraTenantId string = tenant().tenantId
param entraApiAudience string = ''
param entraScopes string = ''
param entraRedirectUri string = ''
@secure()
param entraClientId string = ''
@secure()
param entraClientSecret string = ''

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
param gpt40_DeploymentCapacity int = 500

@description('The default GPT 4.1 model deployment name for the AI Agent')
param gpt41_DeploymentName string = 'gpt-4.1'
@description('The GPT 4.1 model version to use')
param gpt41_ModelVersion string = '2025-04-14'
@description('The GPT 4.1 model deployment capacity')
param gpt41_DeploymentCapacity int = 500

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
// External APIM Parameters
// --------------------------------------------------------------------------------------------------------------
@description('Base URL to facade API')
param apimBaseUrl string = ''
param apimAccessUrl string = ''
@secure()
param apimAccessKey string = ''

// --------------------------------------------------------------------------------------------------------------
// Existing images
// --------------------------------------------------------------------------------------------------------------
param apiImageName string = ''
param UIImageName string = ''

// --------------------------------------------------------------------------------------------------------------
// Other deployment switches
// --------------------------------------------------------------------------------------------------------------
@description('Should resources be created with public access?')
param publicAccessEnabled bool = true
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
@description('Should UI container app be deployed?')
param deployUIApp bool = false

@description('Global Region where the resources will be deployed, e.g. AM (America), EM (EMEA), AP (APAC), CH (China)')
//@allowed(['AM', 'EM', 'AP', 'CH', 'NAA'])
param regionCode string = 'NAA'

@description('Instance number for the application, e.g. 001, 002, etc. This is used to differentiate multiple instances of the same application in the same environment.')
param instanceNumber string = '001' // used to differentiate multiple instances of the same application in the same environment

// // --------------------------------------------------------------------------------------------------------------
// // Additional Tags that may be included or not
// // --------------------------------------------------------------------------------------------------------------
// param costCenterTag string = ''
// param ownerEmailTag string = ''
// param requestorName string = 'UNKNOWN'
// param applicationId string = ''
// param primarySupportProviderTag string = ''

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
var commonTags = tags

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
var costCenterTagObject = costCenterTag == '' ? {} : { 'cost-center': costCenterTag }
var ownerEmailTagObject = ownerEmailTag == ''
  ? {}
  : {
      'application-owner': ownerEmailTag
      'business-owner': ownerEmailTag
      'point-of-contact': ownerEmailTag
    }
// if this bicep was called from AZD, then it needs this tag added to the resource group (at a minimum) to deploy successfully...
var azdTag = azdEnvName != '' ? { 'azd-env-name': azdEnvName } : {}
var tags = union(commonTags, azdTag, costCenterTagObject, ownerEmailTagObject)

// Run a script to dedupe the KeyVault secrets -- this fails on private networks right now so turn if off for them
var deduplicateKVSecrets = publicAccessEnabled ? deduplicateKeyVaultSecrets : false

// if either of these are empty or the value is set to string 'null', then we will not deploy the Entra client secrets
var deployEntraClientSecrets = !(empty(entraClientId) || empty(entraClientSecret) || toLower(entraClientId) == 'null' || toLower(entraClientSecret) == 'null')

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

module apimSecret './modules/security/keyvault-secret.bicep' = {
  name: 'apim-search${deploymentSuffix}'
  params: {
    keyVaultName: keyVault.outputs.name
    secretName: 'apimkey'
    secretValue: apimAccessKey
    existingSecretNames: deduplicateKVSecrets ? keyVaultSecretList.outputs.secretNameList : ''
  }
  dependsOn: [ apim ]
}

module entraClientIdSecret './modules/security/keyvault-secret.bicep' = if (deployEntraClientSecrets) {
  name: 'entraClientId-search${deploymentSuffix}'
  params: {
    keyVaultName: keyVault.outputs.name
    secretName: 'entraclientid'
    secretValue: entraClientId
    existingSecretNames: deduplicateKVSecrets ? keyVaultSecretList.outputs.secretNameList : ''
  }
}
module entraClientSecretSecret './modules/security/keyvault-secret.bicep' = if (deployEntraClientSecrets) {
  name: 'entraClientSecret-search${deploymentSuffix}'
  params: {
    keyVaultName: keyVault.outputs.name
    secretName: 'entraclientsecret'
    secretValue: entraClientSecret
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
    myIpAddress: myIpAddress
    managedIdentityId: identity.outputs.managedIdentityId
  }
  dependsOn: [
    searchService
  ]
}

// --------------------------------------------------------------------------------------------------------------
// I thought these were the new ones but they are not....
// do not use the Foundry files in /modules/ai-foundry....
// use the foundry in /modules/cognitive-services/ai-project.bicep
// --------------------------------------------------------------------------------------------------------------
// module aiFoundryHub './modules/ai-foundry/ai-foundry-hub.bicep' = {
//   name: 'aiHub${deploymentSuffix}'
//   params: {
//     location: location
//     name: resourceNames.outputs.aiHubName
//     tags: commonTags
//     applicationInsightsId: logAnalytics.outputs.applicationInsightsId
//     storageAccountId: storage.outputs.id
//     aiServiceKind: openAI.outputs.kind
//     aiServicesId: openAI.outputs.id
//     aiServicesName: openAI.outputs.name
//     aiServicesTarget: openAI.outputs.endpoint
//     aiSearchId: searchService.outputs.id
//     aiSearchName: searchService.outputs.name
//   }
// }
// module aiFoundryProject './modules/ai-foundry/ai-foundry-project.bicep' = {
//   name: 'aiFoundryProject${deploymentSuffix}'
//   params: {
//     location: location
//     name: resourceNames.outputs.aiHubFoundryProjectName
//     tags: commonTags
//     hubId: aiFoundryHub.outputs.id
//   }
// }

// --------------------------------------------------------------------------------------------------------------
// AI Foundry Hub and Project V2
// Imported from https://github.com/adamhockemeyer/ai-agent-experience
// --------------------------------------------------------------------------------------------------------------
// AI Project and Capability Host
module aiProject './modules/cognitive-services/ai-project.bicep' = {
  name: 'aiProject${deploymentSuffix}'
  params: {
    location: location
    accountName: openAI.outputs.name
    projectName: resourceNames.outputs.aiHubProjectName
    projectDescription: aiProjectDescription
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
// -- Container App Environment ---------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module managedEnvironment './modules/app/managedEnvironment.bicep' = {
  name: 'caenv${deploymentSuffix}'
  params: {
    newEnvironmentName: resourceNames.outputs.caManagedEnvName
    location: location
    logAnalyticsWorkspaceName: logAnalytics.outputs.logAnalyticsWorkspaceName
    logAnalyticsRgName: resourceGroupName
    tags: tags
    publicAccessEnabled: publicAccessEnabled
    containerAppEnvironmentWorkloadProfiles: containerAppEnvironmentWorkloadProfiles
  }
}

var apiTargetPort = 8000
var apiSettings = [
  {
    name: 'API_URL'
    value: 'https://${resourceNames.outputs.containerAppAPIName}.${managedEnvironment.outputs.defaultDomain}/agent'
  }
  { name: 'API_KEY', secretRef: 'apikey' }
  { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', value: logAnalytics.outputs.appInsightsConnectionString }

  { name: 'SEMANTICKERNEL_EXPERIMENTAL_GENAI_ENABLE_OTEL_DIAGNOSTICS', value: 'true' }
  { name: 'SEMANTICKERNEL_EXPERIMENTAL_GENAI_ENABLE_OTEL_DIAGNOSTICS_SENSITIVE', value: 'true' }

  { name: 'AZURE_AI_AGENT_ENDPOINT', value: aiProject.outputs.projectEndpoint }
  { name: 'AZURE_AI_AGENT_MODEL_DEPLOYMENT_NAME', value: gpt41_DeploymentName }

  { name: 'COSMOS_DB_ENDPOINT', value: cosmos.outputs.endpoint }
  { name: 'COSMOS_DB_API_SESSIONS_DATABASE_NAME', value: sessionsDatabaseName }
  { name: 'COSMOS_DB_API_SESSIONS_CONTAINER_NAME', value: sessionsContainerArray[0].name }

  { name: 'APIM_BASE_URL', value: apimBaseUrl }
  { name: 'APIM_ACCESS_URL', value: apimAccessUrl }
  { name: 'APIM_KEY', secretRef: 'apimkey' }

  { name: 'AZURE_CLIENT_ID', value: identity.outputs.managedIdentityClientId }

  { name: 'AZURE_SDK_TRACING_IMPLEMENTATION', value: 'opentelemetry' }
  { name: 'AZURE_TRACING_GEN_AI_CONTENT_RECORDING_ENABLED', value: 'true' }

]
var entraSecuritySettings = deployEntraClientSecrets ? [
  { name: 'ENTRA_TENANT_ID', value: entraTenantId }
  { name: 'ENTRA_API_AUDIENCE', value: entraApiAudience }
  { name: 'ENTRA_SCOPES', value: entraScopes }
  { name: 'ENTRA_REDIRECT_URI', value: entraRedirectUri }
  { name: 'ENTRA_CLIENT_ID', secretRef: 'entraclientid' }
  { name: 'ENTRA_CLIENT_SECRET',secretRef: 'entraclientsecret' }
] : []

var baseSecrets = {
  cosmos: cosmosSecret.outputs.secretUri
  aikey: openAISecret.outputs.secretUri
  docintellikey: documentIntelligenceSecret.outputs.secretUri
  searchkey: searchSecret.outputs.secretUri
  apikey: apiKeySecret.outputs.secretUri
  apimkey: apimSecret.outputs.secretUri
}
var entraSecrets = deployEntraClientSecrets ? {
  entraclientid: entraClientIdSecret.outputs.secretUri
  entraclientsecret: entraClientSecretSecret.outputs.secretUri
} : {}

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
    secrets: union(baseSecrets, entraSecrets) 
    env: union(apiSettings, entraSecuritySettings)
  }
  dependsOn: [containerRegistry, apim]
}

var UITargetPort = 8001
var UISettings = union(apiSettings, [
  { name: 'API_URL', value: 'https://${resourceNames.outputs.containerAppAPIName}.${managedEnvironment.outputs.defaultDomain}/agent' }
])

module containerAppUI './modules/app/containerappstub.bicep' = if (deployUIApp) {
  name: 'ca-UI-stub${deploymentSuffix}'
  params: {
    appName: resourceNames.outputs.containerAppUIName
    managedEnvironmentName: managedEnvironment.outputs.name
    managedEnvironmentRg: managedEnvironment.outputs.resourceGroupName
    workloadProfileName: appContainerAppEnvironmentWorkloadProfileName
    registryName: resourceNames.outputs.ACR_Name
    targetPort: UITargetPort
    userAssignedIdentityName: identity.outputs.managedIdentityName
    location: location
    imageName: UIImageName
    tags: union(tags, { 'azd-service-name': 'UI' })
    deploymentSuffix: deploymentSuffix
    secrets: union(baseSecrets, entraSecrets) 
    env: union(UISettings, entraSecuritySettings)
  }
  dependsOn: [containerRegistry, apim]
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
output UI_CONTAINER_APP_FQDN string = deployUIApp ? containerAppUI.outputs.fqdn : ''
output UI_CONTAINER_APP_NAME string = deployUIApp ? containerAppUI.outputs.name : ''
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
