// ----------------------------------------------------------------------------------------------------
// Assign roles to the service principal or a given user
// ----------------------------------------------------------------------------------------------------
// NOTE: this requires elevated permissions in the resource group
// Contributor is not enough, you need Owner or User Access Administrator
// ----------------------------------------------------------------------------------------------------
// For a list of Role Id's see https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
// ----------------------------------------------------------------------------------------------------

param identityPrincipalId string
@allowed(['ServicePrincipal', 'User'])
param principalType string = 'ServicePrincipal'

param registryName string = ''
// param registryResourceGroupName string = resourceGroup().name
param storageAccountName string = ''
// param storageResourceGroupName string = resourceGroup().name
param aiSearchName string = ''
// param aiSearchResourceGroupName string = resourceGroup().name
param aiServicesName string = ''
// param aiServicesResourceGroupName string = resourceGroup().name
param cosmosName string = ''
// param cosmosResourceGroupName string = resourceGroup().name
param keyVaultName string = ''
// param keyVaultResourceGroupName string = resourceGroup().name
param apimName string = ''
// param apimResourceGroupName string = resourceGroup().name

// param aiHubName string = ''
// // param aiHubResourceGroupName string = resourceGroup().name

// ----------------------------------------------------------------------------------------------------
var roleDefinitions = loadJsonContent('../../data/roleDefinitions.json')
var addRegistryRoles = !empty(registryName)
var addStorageRoles = !empty(storageAccountName)
var addSearchRoles = !empty(aiSearchName)
var addCogServicesRoles = !empty(aiServicesName)
var addCosmosRoles = !empty(cosmosName)
var addKeyVaultRoles = !empty(keyVaultName)
var addApimRoles = !empty(apimName)
// var addAIHubRoles = !empty(aiHubName)

// ----------------------------------------------------------------------------------------------------
// Registry Roles
// ----------------------------------------------------------------------------------------------------
resource registry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = if (addRegistryRoles) {
  name: registryName
  // scope: resourceGroup(registryResourceGroupName)
}
resource registry_Role_AcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (addRegistryRoles) {
  name: guid(registry.id, identityPrincipalId, roleDefinitions.containerregistry.acrPullRoleId)
  scope: registry
  properties: {
    principalId: identityPrincipalId
    principalType: principalType
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.containerregistry.acrPullRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to pull images from the registry ${registryName}'
  }
}

// ----------------------------------------------------------------------------------------------------
// Storage Roles
// ----------------------------------------------------------------------------------------------------
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' existing = if (addStorageRoles) {
  name: storageAccountName
  // scope: resourceGroup(storageResourceGroupName)
}
resource storage_Role_BlobContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (addStorageRoles) {
  name: guid(storageAccount.id, identityPrincipalId, roleDefinitions.storage.blobDataContributorRoleId)
  scope: storageAccount
  properties: {
    principalId: identityPrincipalId
    principalType: principalType
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.storage.blobDataContributorRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to write to the storage account ${storageAccountName} Blob'
  }
}
resource storage_Role_TableContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (addStorageRoles) {
  name: guid(storageAccount.id, identityPrincipalId, roleDefinitions.storage.tableContributorRoleId)
  scope: storageAccount
  properties: {
    principalId: identityPrincipalId
    principalType: principalType
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.storage.tableContributorRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to write to the storage account ${storageAccountName} Table'
  }
}
resource storage_Role_QueueContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (addStorageRoles) {
  name: guid(storageAccount.id, identityPrincipalId, roleDefinitions.storage.queueDataContributorRoleId)
  scope: storageAccount
  properties: {
    principalId: identityPrincipalId
    principalType: principalType
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.storage.queueDataContributorRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to write to the storage account ${storageAccountName} Queue'
  }
}

// ----------------------------------------------------------------------------------------------------
// Cognitive Services Roles
// ----------------------------------------------------------------------------------------------------
resource aiService 'Microsoft.CognitiveServices/accounts@2024-06-01-preview' existing = if (addCogServicesRoles) {
  name: aiServicesName
  // scope: resourceGroup(aiServicesResourceGroupName)
}
resource cognitiveServices_Role_OpenAIUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (addCogServicesRoles) {
  name: guid(aiService.id, identityPrincipalId, roleDefinitions.openai.cognitiveServicesOpenAIUserRoleId)
  scope: aiService
  properties: {
    principalId: identityPrincipalId
    principalType: principalType
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.openai.cognitiveServicesOpenAIUserRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to be OpenAI User'
  }
}
resource cognitiveServices_Role_OpenAIContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (addCogServicesRoles) {
  name: guid(aiService.id, identityPrincipalId, roleDefinitions.openai.cognitiveServicesOpenAIContributorRoleId)
  scope: aiService
  properties: {
    principalId: identityPrincipalId
    principalType: principalType
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.openai.cognitiveServicesOpenAIContributorRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to be OpenAI Contributor'
  }
}
resource cognitiveServices_Role_User 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (addCogServicesRoles) {
  name: guid(aiService.id, identityPrincipalId, roleDefinitions.openai.cognitiveServicesUserRoleId)
  scope: aiService
  properties: {
    principalId: identityPrincipalId
    principalType: principalType
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.openai.cognitiveServicesUserRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to be a Cognitive Services User'
  }
}
resource cognitiveServices_Role_Contributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (addCogServicesRoles) {
  name: guid(aiService.id, identityPrincipalId, roleDefinitions.openai.cognitiveServicesContributorRoleId)
  scope: aiService
  properties: {
    principalId: identityPrincipalId
    principalType: principalType
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.openai.cognitiveServicesContributorRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to be a Cognitive Services Contributor'
  }
}
resource cognitiveServices_Role_AzureAIEngineer 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (addCogServicesRoles) {
  name: guid(aiService.id, identityPrincipalId, roleDefinitions.openai.cognitiveServicesAzureAIEngineerRoleId)
  scope: aiService
  properties: {
    principalId: identityPrincipalId
    principalType: principalType
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.openai.cognitiveServicesAzureAIEngineerRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to be a Cognitive Services Azure AI Engineer'
  }
}

// ----------------------------------------------------------------------------------------------------
// Search Roles
// ----------------------------------------------------------------------------------------------------
resource searchService 'Microsoft.Search/searchServices@2024-06-01-preview' existing = if (addSearchRoles) {
  name: aiSearchName
  // scope: resourceGroup(aiSearchResourceGroupName)
}
resource search_Role_IndexDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (addSearchRoles) {
  name: guid(searchService.id, identityPrincipalId, roleDefinitions.search.indexDataContributorRoleId)
  scope: searchService
  properties: {
    principalId: identityPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.search.indexDataContributorRoleId)
    principalType: principalType
    description: 'Permission for ${principalType} ${identityPrincipalId} to use the modify search service indexes'
  }
}
resource search_Role_IndexDataReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (addSearchRoles) {
  name: guid(searchService.id, identityPrincipalId, roleDefinitions.search.indexDataReaderRoleId)
  scope: searchService
  properties: {
    principalId: identityPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.search.indexDataReaderRoleId)
    principalType: principalType
    description: 'Permission for ${principalType} ${identityPrincipalId} to use the read search service indexes'
  }
}
resource search_Role_ServiceContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (addSearchRoles) {
  name: guid(searchService.id, identityPrincipalId, roleDefinitions.search.serviceContributorRoleId)
  scope: searchService
  properties: {
    principalId: identityPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.search.serviceContributorRoleId)
    principalType: principalType
    description: 'Permission for ${principalType} ${identityPrincipalId} to be a search service contributor'
  }
}

// ----------------------------------------------------------------------------------------------------
// Cosmos Database Roles
// ----------------------------------------------------------------------------------------------------
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-08-15' existing = if (addCosmosRoles) {
  name: cosmosName
  //scope: resourceGroup(cosmosResourceGroupName)
}

resource cosmosDbUserAccessRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-08-15' = if (addCosmosRoles) {
  name: guid(cosmosAccount.id, identityPrincipalId, roleDefinitions.cosmos.dataContributorRoleId)
  parent: cosmosAccount
  properties: {
    principalId: identityPrincipalId
    roleDefinitionId: '${resourceGroup().id}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosAccount.name}/sqlRoleDefinitions/${roleDefinitions.cosmos.dataContributorRoleId}'
    scope: cosmosAccount.id
  }
}

// ----------------------------------------------------------------------------------------------------
// KeyVault Roles
// ----------------------------------------------------------------------------------------------------
resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = if (addKeyVaultRoles) {
  name: keyVaultName
  //scope: resourceGroup(keyVaultNameResourceGroupName)
}

resource keyVaultSecretsOfficerAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (addKeyVaultRoles) {
  name: guid(keyVault.id, identityPrincipalId, roleDefinitions.keyvault.secretsOfficerRoleId)
  scope: keyVault
  properties: {
    principalId: identityPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.keyvault.secretsOfficerRoleId)
    principalType: principalType
    description: 'Permission for ${principalType} ${identityPrincipalId} to be a Key Vault Secrets Officer'
  }
}

// ----------------------------------------------------------------------------------------------------
// APIM Roles - assign to Identity running APIM
// ----------------------------------------------------------------------------------------------------
resource apimService 'Microsoft.ApiManagement/service@2024-05-01' existing = if (addApimRoles) {
  name: apimName
  //scope: resourceGroup(apimResourceGroupName)
}

resource apimReaderAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (addApimRoles) {
  name: guid(apimService.id, identityPrincipalId, roleDefinitions.apim.serviceReaderRoleId)
  scope: apimService
  properties: {
    principalId: identityPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.apim.serviceReaderRoleId)
    principalType: principalType
    description: 'Permission for ${principalType} ${identityPrincipalId} to be a APIM Service Reader'
  }
}

// // ----------------------------------------------------------------------------------------------------
// // AI Hub Roles
// // ----------------------------------------------------------------------------------------------------
// resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-10-01' existing = if (addAIHubRoles) {
//   name: aiHubName
//   //scope: resourceGroup(aiHubResourceGroupName)
// }
// resource aiHub_Role_DataScientist 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (addAIHubRoles) {
//   name: guid(aiHub.id, identityPrincipalId, roleDefinitions.ml.dataScientistRole)
//   scope: aiHub
//   properties: {
//     principalId: identityPrincipalId
//     principalType: principalType
//     roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.ml.dataScientistRole)
//     description: 'Permission for ${principalType} ${identityPrincipalId} to be in Data Scientist Role'
//   }
// }

// ----------------------------------------------------------------------------------------------------
output containerRegistryRoleAssignmentIds object = (addRegistryRoles) ? {
  registry_AcrPull_RoleId : registry_Role_AcrPull.id
} : {}

output storageRoleAssignmentIds object = (addStorageRoles) ? {
  storage_BlobContributor_RoleId : storage_Role_BlobContributor.id
  storage_TableContributor_RoleId : storage_Role_TableContributor.id
  storage_QueueContributor_RoleId : storage_Role_QueueContributor.id
} : {}

output cognitiveServicesRoleAssignmentIds object = (addCogServicesRoles) ? {
  cognitiveServices_OpenAIUser_RoleId : cognitiveServices_Role_OpenAIUser.id
  cognitiveServices_OpenAIContributor_RoleId : cognitiveServices_Role_OpenAIContributor.id
  cognitiveServices_User_RoleId : cognitiveServices_Role_User.id
  cognitiveServices_Contributor_RoleId : cognitiveServices_Role_Contributor.id
  cognitiveServices_AzureAIEngineer_RoleId : cognitiveServices_Role_AzureAIEngineer.id
} : {}

output searchServiceRoleAssignmentIds object = (addSearchRoles) ? {
  search_IndexDataContributor_RoleId : search_Role_IndexDataContributor.id
  search_IndexDataReader_RoleId : search_Role_IndexDataReader.id
  search_ServiceContributor_RoleId : search_Role_ServiceContributor.id
} : {}

output cosmosRoleAssignmentIds object = (addCosmosRoles) ? {
  cosmos_UserAccess_RoleId : cosmosDbUserAccessRoleAssignment.id
} : {}

output keyVaultRoleAssignmentIds object = (addKeyVaultRoles) ? {
  keyVault_SecretsOfficer_RoleId : keyVaultSecretsOfficerAssignment.id
} : {}
