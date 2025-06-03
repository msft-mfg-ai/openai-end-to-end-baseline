/*
Connections enable your AI applications to access tools and objects managed elsewhere in or outside of Azure.

This example demonstrates how to add an Azure Application Insights connection.

Only one application insights can be set on a project at a time.
*/
param aiFoundryName string
param connectedResourceName string = 'st${aiFoundryName}'
param location string = 'global'
param tags object
 
// Refers your existing Azure AI Foundry resource
resource aiFoundry 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: aiFoundryName
  scope: resourceGroup()
}


// Conditionally creates a new Azure AI Search resource
resource bingSearch 'Microsoft.Bing/accounts@2025-05-01-preview' = {
  name: connectedResourceName
  location: location
  tags: tags
  sku: {
    name: 'G1'
  }
  properties: {
    statisticsEnabled: false
  }
  kind: 'Bing.Grounding'
}

// Creates the Azure Foundry connection to your Bing resource
resource connection 'Microsoft.CognitiveServices/accounts/connections@2025-04-01-preview' = {
  name: 'binggrounding'
  parent: aiFoundry
  properties: {
    category: 'GroundingWithBingSearch'
    target: 'https://api.bing.microsoft.com/'
    authType: 'ApiKey'
    isSharedToAll: true
    isDefault: true
    credentials: {
      key: '${listKeys(bingSearch.id, '2020-06-10').key1}'
    }
    metadata: {
      Type: 'bing_grounding'
      ApiType: 'Azure'
      ResourceId: bingSearch.id
    }
  }
}

output BING_CONNECTION_NAME string = connection.name
output BING_CONNECTION_ID string = connection.id
