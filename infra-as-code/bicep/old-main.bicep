// --------------------------------------------------------------------------------------------------------------
// Main bicep file that deploys EVERYTHING for the application, with optional parameters for existing resources.
// --------------------------------------------------------------------------------------------------------------
// You can test it with these commands:
//   Most basic of test commands:
//     az deployment group create -n manual --resource-group rg_smart_flow_test --template-file 'main.bicep' --parameters environmentName=dev applicationName=myApp
//   Deploy with existing resources specified in a parameter file:
//     az deployment group create -n manual --resource-group rg_smart_flow_test --template-file 'main.bicep' --parameters main-complete-existing.bicepparam
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
param vnetPrefix string = '10.2.0.0/16'
@description('If new VNET, this is the Subnet name for the private endpoints')
param subnet1Name string = ''
@description('If new VNET, this is the Subnet addresses for the private endpoints, i.e. 10.2.0.0/26') //Provided subnet must have a size of at least /23
param subnet1Prefix string = '10.2.0.0/23'
@description('If new VNET, this is the Subnet name for the application')
param subnet2Name string = ''
@description('If new VNET, this is the Subnet addresses for the application, i.e. 10.2.2.0/23') // Provided subnet must have a size of at least /23
param subnet2Prefix string = '10.2.2.0/23'

// --------------------------------------------------------------------------------------------------------------
// Existing container registry?
// --------------------------------------------------------------------------------------------------------------
@description('If you provide this is will be used instead of creating a new Registry')
param existing_ACR_Name string = ''
@description('If you provide this is will be used instead of creating a new Registry')
param existing_ACR_ResourceGroupName string = ''

// --------------------------------------------------------------------------------------------------------------
// Existing monitoring?
// --------------------------------------------------------------------------------------------------------------
@description('If you provide this is will be used instead of creating a new Workspace')
param existing_LogAnalytics_Name string = ''
@description('If you provide this is will be used instead of creating a new App Insights')
param existing_AppInsights_Name string = ''

// --------------------------------------------------------------------------------------------------------------
// Existing Container App Environment?
// --------------------------------------------------------------------------------------------------------------
@description('If you provide this is will be used instead of creating a new Container App Environment')
param existing_managedAppEnv_Name string = ''
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
// Existing OpenAI resources?
// --------------------------------------------------------------------------------------------------------------
@description('Name of an existing Cognitive Services account to use')
param existing_CogServices_Name string = ''
@description('Resource Group where existing Cognitive Services account Lives')
param existing_CogServices_ResourceGroupName string = ''

@description('Name of an existing Search Services account to use')
param existing_SearchService_Name string = ''
@description('Resource Group where existing Search Services account Lives')
param existing_SearchService_ResourceGroupName string = ''

@description('Friendly name for your Azure AI resource')
param aiProjectFriendlyName string = 'Agents Project resource'
@description('Description of your Azure AI resource displayed in AI studio')
param aiProjectDescription string = 'This is an example AI Project resource for use in Azure AI Studio.'

// --------------------------------------------------------------------------------------------------------------
// Existing Cosmos resources?
// --------------------------------------------------------------------------------------------------------------
@description('Name of an existing Cosmos account to use')
param existing_Cosmos_Name string = ''
@description('Resource Group where existing Cosmos account Lives')
param existing_Cosmos_ResourceGroupName string = ''

// --------------------------------------------------------------------------------------------------------------
// Existing Key Vault?
// --------------------------------------------------------------------------------------------------------------
@description('Name of an existing Key Vault to use')
param existing_KeyVault_Name string = ''
@description('Resource Group where existing Key Vault Lives')
param existing_KeyVault_ResourceGroupName string = ''

// --------------------------------------------------------------------------------------------------------------
// AI Hub Parameters
// --------------------------------------------------------------------------------------------------------------
@description('Should we deploy an AI Foundry Hub?')
param deployAIHub bool = true

// --------------------------------------------------------------------------------------------------------------
// Existing images
// --------------------------------------------------------------------------------------------------------------
param apiImageName string = ''
param batchImageName string = ''

// --------------------------------------------------------------------------------------------------------------
// Other deployment switches
// --------------------------------------------------------------------------------------------------------------
@description('Should resources be created with public access?')
param publicAccessEnabled bool = true
@description('Create DNS Zones?')
param createDnsZones bool = true
@description('Add Role Assignments for the user assigned identity?')
param addRoleAssignments bool = true
@description('Should we run a script to dedupe the KeyVault secrets? (this fails on private networks right now)')
param deduplicateKeyVaultSecrets bool = true
@description('Set this if you want to append all the resource names with a unique token')
param appendResourceTokens bool = false
@description('Should batch container app be deployed?')
param deployBatchApp bool = true

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

// if this bicep was called from AZD, then it needs this tag added to the resource group (at a minimum) to deploy successfully...
var azdTag = azdEnvName != '' ? { 'azd-env-name': azdEnvName } : {}

var commonTags = {
  LastDeployed: runDateTime
  Application: appName
  ApplicationName: applicationName
  Environment: environmentName
}
var tags = union(commonTags, azdTag)

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
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- VNET ------------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module vnet './core/networking/vnet.bicep' = {
  name: 'vnet${deploymentSuffix}'
  params: {
    location: location
    existingVirtualNetworkName: existingVnetName
    existingVnetResourceGroupName: existingVnetResourceGroupName
    newVirtualNetworkName: resourceNames.outputs.vnet_Name
    vnetAddressPrefix: vnetPrefix
    subnet1Name: !empty(subnet1Name) ? subnet1Name : resourceNames.outputs.vnetPeSubnetName
    subnet1Prefix: subnet1Prefix
    subnet2Name: !empty(subnet2Name) ? subnet2Name : resourceNames.outputs.vnetAppSubnetName
    subnet2Prefix: subnet2Prefix
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- Container Registry ----------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module containerRegistry './core/host/containerregistry.bicep' = {
  name: 'containerregistry${deploymentSuffix}'
  params: {
    existingRegistryName: existing_ACR_Name
    existing_ACR_ResourceGroupName: existing_ACR_ResourceGroupName
    newRegistryName: resourceNames.outputs.ACR_Name
    location: location
    acrSku: 'Premium'
    tags: tags
    publicAccessEnabled: publicAccessEnabled
    privateEndpointName: 'pe-${resourceNames.outputs.ACR_Name}'
    privateEndpointSubnetId: vnet.outputs.subnet1ResourceId
    myIpAddress: myIpAddress
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- Log Analytics Workspace and App Insights ------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module logAnalytics './core/monitor/loganalytics.bicep' = {
  name: 'law${deploymentSuffix}'
  params: {
    existingLogAnalyticsName: existing_LogAnalytics_Name
    existingLogAnalyticsRgName: resourceGroupName
    newLogAnalyticsName: resourceNames.outputs.logAnalyticsWorkspaceName
    existingApplicationInsightsName: existing_AppInsights_Name
    newApplicationInsightsName: resourceNames.outputs.appInsightsName
    location: location
    tags: tags
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- Storage Resources ---------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module storage './core/storage/storage-account.bicep' = {
  name: 'storage${deploymentSuffix}'
  params: {
    name: resourceNames.outputs.storageAccountName
    location: location
    tags: tags
    // publicNetworkAccess: publicAccessEnabled
    privateEndpointSubnetId: vnet.outputs.subnet1ResourceId
    privateEndpointBlobName: 'pe-blob-${resourceNames.outputs.storageAccountName}'
    privateEndpointQueueName: 'pe-queue-${resourceNames.outputs.storageAccountName}'
    privateEndpointTableName: 'pe-table-${resourceNames.outputs.storageAccountName}'
    myIpAddress: myIpAddress
    containers: ['data', 'batch-input', 'batch-output']
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- Key Vault Resources ---------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module identity './core/iam/identity.bicep' = {
  name: 'app-identity${deploymentSuffix}'
  params: {
    identityName: resourceNames.outputs.userAssignedIdentityName
    location: location
  }
}
module appIdentityRoleAssignments './core/iam/role-assignments.bicep' = if (addRoleAssignments) {
  name: 'identity-access${deploymentSuffix}'
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

module adminUserRoleAssignments './core/iam/role-assignments.bicep' = if (addRoleAssignments && !empty(principalId)) {
  name: 'user-access${deploymentSuffix}'
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

module keyVault './core/security/keyvault.bicep' = {
  name: 'keyvault${deploymentSuffix}'
  params: {
    location: location
    commonTags: tags
    keyVaultName: resourceNames.outputs.keyVaultName
    existingKeyVaultName: existing_KeyVault_Name
    existingKeyVaultResourceGroupName: existing_KeyVault_ResourceGroupName
    keyVaultOwnerUserId: principalId
    adminUserObjectIds: [identity.outputs.managedIdentityPrincipalId]
    publicNetworkAccess: publicAccessEnabled ? 'Enabled' : 'Disabled'
    keyVaultOwnerIpAddress: myIpAddress
    createUserAssignedIdentity: false
    privateEndpointName: 'pe-${resourceNames.outputs.keyVaultName}'
    privateEndpointSubnetId: vnet.outputs.subnet1ResourceId
  }
}

module keyVaultSecretList './core/security/keyvault-list-secret-names.bicep' = if (deduplicateKVSecrets) {
  name: 'keyVault-Secret-List-Names${deploymentSuffix}'
  params: {
    keyVaultName: keyVault.outputs.name
    location: location
    userManagedIdentityId: identity.outputs.managedIdentityId
  }
}

var apiKeyValue = uniqueString(resourceGroup().id, location, 'api-key', runDateTime)
module apiKeySecret './core/security/keyvault-secret.bicep' = {
  name: 'secret-api-key${deploymentSuffix}'
  params: {
    keyVaultName: keyVault.outputs.name
    secretName: 'api-key'
    existingSecretNames: deduplicateKVSecrets ? keyVaultSecretList.outputs.secretNameList : ''
    secretValue: apiKeyValue
  }
}

module cosmosSecret './core/security/keyvault-cosmos-secret.bicep' = {
  name: 'secret-cosmos${deploymentSuffix}'
  params: {
    keyVaultName: keyVault.outputs.name
    secretName: cosmos.outputs.keyVaultSecretName
    cosmosAccountName: cosmos.outputs.name
    existingSecretNames: deduplicateKVSecrets ? keyVaultSecretList.outputs.secretNameList : ''
  }
}

module storageSecret './core/security/keyvault-storage-secret.bicep' = {
  name: 'secret-storage${deploymentSuffix}'
  params: {
    keyVaultName: keyVault.outputs.name
    secretName: storage.outputs.storageAccountConnectionStringSecretName
    storageAccountName: storage.outputs.name
    existingSecretNames: deduplicateKVSecrets ? keyVaultSecretList.outputs.secretNameList : ''
  }
}

module openAISecret './core/security/keyvault-cognitive-secret.bicep' = {
  name: 'secret-openai${deploymentSuffix}'
  params: {
    keyVaultName: keyVault.outputs.name
    secretName: openAI.outputs.cognitiveServicesKeySecretName
    cognitiveServiceName: openAI.outputs.name
    cognitiveServiceResourceGroup: openAI.outputs.resourceGroupName
    existingSecretNames: deduplicateKVSecrets ? keyVaultSecretList.outputs.secretNameList : ''
  }
}

module documentIntelligenceSecret './core/security/keyvault-cognitive-secret.bicep' = {
  name: 'secret-doc-intelligence${deploymentSuffix}'
  params: {
    keyVaultName: keyVault.outputs.name
    secretName: documentIntelligence.outputs.keyVaultSecretName
    cognitiveServiceName: documentIntelligence.outputs.name
    cognitiveServiceResourceGroup: documentIntelligence.outputs.resourceGroupName
    existingSecretNames: deduplicateKVSecrets ? keyVaultSecretList.outputs.secretNameList : ''
  }
}

module searchSecret './core/security/keyvault-search-secret.bicep' = {
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
var cosmosContainerArray = [
  { name: 'AgentLog', partitionKey: '/requestId' }
  { name: 'UserDocuments', partitionKey: '/userId' }
  { name: uiChatContainerName, partitionKey: '/chatId' }
]
module cosmos './core/database/cosmosdb.bicep' = {
  name: 'cosmos${deploymentSuffix}'
  params: {
    accountName: resourceNames.outputs.cosmosName
    existingAccountName: existing_Cosmos_Name
    existingCosmosResourceGroupName: existing_Cosmos_ResourceGroupName
    databaseName: uiDatabaseName
    containerArray: cosmosContainerArray
    location: location
    tags: tags
    privateEndpointSubnetId: vnet.outputs.subnet1ResourceId
    privateEndpointName: 'pe-${resourceNames.outputs.cosmosName}'
    managedIdentityPrincipalId: identity.outputs.managedIdentityPrincipalId
    userPrincipalId: principalId
    publicNetworkAccess: publicAccessEnabled ? 'enabled' : 'disabled'
    myIpAddress: myIpAddress
  }
}

// --------------------------------------------------------------------------------------------------------------
// -- Cognitive Services Resources ------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module searchService './core/search/search-services.bicep' = {
  name: 'search${deploymentSuffix}'
  params: {
    location: location
    name: resourceNames.outputs.searchServiceName
    existingSearchServiceName: existing_SearchService_Name
    existingSearchServiceResourceGroupName: existing_SearchService_ResourceGroupName
    publicNetworkAccess: publicAccessEnabled ? 'enabled' : 'disabled'
    myIpAddress: myIpAddress
    privateEndpointSubnetId: vnet.outputs.subnet1ResourceId
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
module openAI './core/ai/cognitive-services.bicep' = {
  name: 'openai${deploymentSuffix}'
  params: {
    managedIdentityId: identity.outputs.managedIdentityId
    existing_CogServices_Name: existing_CogServices_Name
    existing_CogServices_ResourceGroupName: existing_CogServices_ResourceGroupName
    name: resourceNames.outputs.cogServiceName
    location: openAI_deploy_location // this may be different than the other resources
    pe_location: location
    tags: tags
    textEmbedding: {
      DeploymentName: 'text-embedding'
      ModelName: 'text-embedding-ada-002'
      ModelVersion: '2'
      DeploymentCapacity: 30
    }
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
    privateEndpointSubnetId: vnet.outputs.subnet1ResourceId
    privateEndpointName: 'pe-${resourceNames.outputs.cogServiceName}'
    myIpAddress: myIpAddress
  }
  dependsOn: [
    searchService
  ]
}

module documentIntelligence './core/ai/document-intelligence.bicep' = {
  name: 'doc-intelligence${deploymentSuffix}'
  params: {
    existing_CogServices_Name: '' //existing_DocumentIntelligence_Name
    existing_CogServices_ResourceGroupName: '' //existing_DocumentIntelligence_RG_Name
    name: resourceNames.outputs.documentIntelligenceServiceName
    location: location // this may be different than the other resources
    tags: tags
    publicNetworkAccess: publicAccessEnabled ? 'enabled' : 'disabled'
    privateEndpointSubnetId: vnet.outputs.subnet1ResourceId
    privateEndpointName: 'pe-${resourceNames.outputs.documentIntelligenceServiceName}'
    myIpAddress: myIpAddress
    managedIdentityId: identity.outputs.managedIdentityId
  }
  dependsOn: [
    searchService
  ]
}

module aiHub 'core/ai/ai-hub-secure.bicep' = if (deployAIHub) {
  name: 'aiHub${deploymentSuffix}'
  params: {
    aiHubName: resourceNames.outputs.aiHubName
    location: location
    tags: tags

    // dependent resources
    aiServicesId: openAI.outputs.id
    aiServicesTarget: openAI.outputs.endpoint
    aiSearchName: searchService.outputs.name
    applicationInsightsId: logAnalytics.outputs.applicationInsightsId
    containerRegistryId: containerRegistry.outputs.id
    keyVaultId: keyVault.outputs.id
    storageAccountId: storage.outputs.id

    // add data scientist role to user and application
    addRoleAssignments: addRoleAssignments
    userObjectId: principalId
    userObjectType: 'User'
    //managedIdentityResourceId: identity.outputs.managedIdentityId
    managedIdentityPrincipalId: identity.outputs.managedIdentityPrincipalId
    managedIdentityType: 'ServicePrincipal'
  }
}

module aiProject 'core/ai/ai-hub-project.bicep' = if (deployAIHub) {
  name: 'aiProject${deploymentSuffix}'
  params: {
    aiProjectName: resourceNames.outputs.aiHubProjectName
    aiProjectFriendlyName: aiProjectFriendlyName
    aiProjectDescription: aiProjectDescription
    location: location
    tags: tags
    aiHubId: aiHub.outputs.id
  }
}


// --------------------------------------------------------------------------------------------------------------
// -- DNS ZONES ---------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
module allDnsZones './core/networking/all-zones.bicep' = if (createDnsZones) {
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
module managedEnvironment './core/host/managedEnvironment.bicep' = {
  name: 'caenv${deploymentSuffix}'
  params: {
    existingEnvironmentName: existing_managedAppEnv_Name
    newEnvironmentName: resourceNames.outputs.caManagedEnvName
    location: location
    logAnalyticsWorkspaceName: logAnalytics.outputs.logAnalyticsWorkspaceName
    logAnalyticsRgName: resourceGroupName
    appSubnetId: vnet.outputs.subnet2ResourceId
    tags: tags
    publicAccessEnabled: publicAccessEnabled
    containerAppEnvironmentWorkloadProfiles: containerAppEnvironmentWorkloadProfiles
  }
}

// Applications use managed identity to access resources, keys are not needed but kept for future reference
// var accessKeys = [
//   { name: 'AOAIStandardServiceKey', secretRef: 'aikey' }
//   { name: 'AzureDocumentIntelligenceKey', secretRef: 'docintellikey' }
//   { name: 'AzureAISearchKey', secretRef: 'searchkey' }
//   { name: 'CosmosDbKey', secretRef: 'cosmos' }
// ]

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

module containerAppAPI './core/host/containerappstub.bicep' = {
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
module containerAppBatch './core/host/containerappstub.bicep' = if (deployBatchApp) {
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
// -- Outputs ---------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
output SUBSCRIPTION_ID string = subscription().subscriptionId
output ACR_NAME string = containerRegistry.outputs.name
output ACR_URL string = containerRegistry.outputs.loginServer
output AI_ENDPOINT string = openAI.outputs.endpoint
output AI_HUB_ID string = deployAIHub ? aiHub.outputs.id : ''
output AI_HUB_NAME string = deployAIHub ? aiHub.outputs.name : ''
output AI_PROJECT_NAME string = resourceNames.outputs.aiHubProjectName
output AI_SEARCH_ENDPOINT string = searchService.outputs.endpoint
output API_CONTAINER_APP_FQDN string = containerAppAPI.outputs.fqdn
output API_CONTAINER_APP_NAME string = containerAppAPI.outputs.name
output API_KEY string = apiKeyValue
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
output VNET_CORE_ID string = vnet.outputs.vnetResourceId
output VNET_CORE_NAME string = vnet.outputs.vnetName
output VNET_CORE_PREFIX string = vnet.outputs.vnetAddressPrefix
