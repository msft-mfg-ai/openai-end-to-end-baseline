param accountName string
param location string
param projectName string
param projectDescription string
param displayName string

param aiSearchName string
param aiSearchServiceResourceGroupName string
param aiSearchServiceSubscriptionId string

param cosmosDBName string
param cosmosDBSubscriptionId string
param cosmosDBResourceGroupName string

param azureStorageName string
param azureStorageSubscriptionId string
param azureStorageResourceGroupName string

// param appInsightsName string
// param appInsightsSubscriptionId string
// param appInsightsResourceGroupName string

resource searchService 'Microsoft.Search/searchServices@2024-06-01-preview' existing = {
  name: aiSearchName
  scope: resourceGroup(aiSearchServiceSubscriptionId, aiSearchServiceResourceGroupName)
}
resource cosmosDBAccount 'Microsoft.DocumentDB/databaseAccounts@2024-12-01-preview' existing = {
  name: cosmosDBName
  scope: resourceGroup(cosmosDBSubscriptionId, cosmosDBResourceGroupName)
}
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: azureStorageName
  scope: resourceGroup(azureStorageSubscriptionId, azureStorageResourceGroupName)
}

// resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
//   name: appInsightsName
//   scope: resourceGroup(appInsightsSubscriptionId, appInsightsResourceGroupName)
// }

resource account 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: accountName
  scope: resourceGroup()
}

resource project 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' = {
  parent: account
  name: projectName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: projectDescription
    displayName: displayName
  }

  resource project_connection_cosmosdb_account 'connections@2025-04-01-preview' = {
    name: cosmosDBName
    properties: {
      category: 'CosmosDB'
      target: cosmosDBAccount.properties.documentEndpoint
      authType: 'AAD'
      metadata: {
        ApiType: 'Azure'
        ResourceId: cosmosDBAccount.id
        location: cosmosDBAccount.location
      }
    }
  }

  resource project_connection_azure_storage 'connections@2025-04-01-preview' = {
    name: azureStorageName
    properties: {
      category: 'AzureStorageAccount'
      target: storageAccount.properties.primaryEndpoints.blob
      authType: 'AAD'
      metadata: {
        ApiType: 'Azure'
        ResourceId: storageAccount.id
        location: storageAccount.location
      }
    }
  }

  resource project_connection_azureai_search 'connections@2025-04-01-preview' = {
    name: aiSearchName
    properties: {
      category: 'CognitiveSearch'
      target: 'https://${aiSearchName}.search.windows.net'
      authType: 'AAD'
      metadata: {
        ApiType: 'Azure'
        ResourceId: searchService.id
        location: searchService.location
      }
    }
  }

  // Gets error:  Multiple connection with same category (AppInsights) created, we only allow to have 1 connection for category (AppInsights),
  //   existing connection (applicationInsights), new connection (appi-mfgaicw-lyle-am-009)  (Code: ValidationError)

  // Creates the Azure Foundry connection to your Azure App Insights resource
  // resource connection 'connections@2025-04-01-preview' = {
  //   name: appInsightsName
  //   properties: {
  //     category: 'AppInsights'
  //     target: appInsights.id
  //     authType: 'ApiKey'
  //     isSharedToAll: true
  //     credentials: {
  //       key: appInsights.properties.ConnectionString
  //     }
  //     metadata: {
  //       ApiType: 'Azure'
  //       ResourceId: appInsights.id
  //     }
  //   }
  // }
}

output projectName string = project.name
output projectId string = project.id
output projectPrincipalId string = project.identity.principalId
output projectEndpoint string = project.properties.endpoints['AI Foundry API']

#disable-next-line BCP053
output projectWorkspaceId string = project.properties.internalId

// BYO connection names
output cosmosDBConnection string = cosmosDBName
output azureStorageConnection string = azureStorageName
output aiSearchConnection string = aiSearchName
output projectConnectionString string = 'https://${accountName}.services.ai.azure.com/api/projects/${projectName}'

