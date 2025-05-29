// Copied from https://github.com/Azure/azure-quickstart-templates/tree/master/quickstarts/microsoft.machinelearningservices/aistudio-basics
// See also: https://learn.microsoft.com/en-us/azure/ai-studio/how-to/create-azure-ai-hub-template
// Creates an Azure AI Hub resource with proxied endpoints for the Azure AI services provider

@description('Azure region used for the deployment of the Azure AI Hub.')
param location string

@description('Set of tags to apply to the Azure AI Hub.')
param tags object

@description('Name for the Azure AI Hub resource.')
param aiHubName string

@description('Friendly name for your Azure AI Hub resource, displayed in the Studio UI.')
param aiHubFriendlyName string = aiHubName

@description('Description of your Azure AI Hub resource, displayed in the Studio UI.')
param aiHubDescription string = 'This is an AI Foundry for use with the Smart-Flow application.'

@description('Resource ID of the Azure Application Insights resource for storing diagnostics logs.')
param applicationInsightsId string

@description('Resource ID of the Azure Container Registry resource for storing Docker images for models.')
param containerRegistryId string

@description('Resource ID of the Azure Key Vault resource for storing connection strings.')
param keyVaultId string

@description('Resource ID of the Azure Storage Account resource for storing workspace data.')
param storageAccountId string

@description('Resource ID of the Azure AI Services resource for connecting AI capabilities.')
param aiServicesId string

@description('Target endpoint for the Azure AI Services resource to link to the Azure AI Hub.')
param aiServicesTarget string

@description('Name AI Search resource')
param aiSearchName string
param aiSearchResourceGroupName string = resourceGroup().name

var acsConnectionName = '${aiHubName}-connection-AISearch'
var aoaiConnectionName  = '${aiHubName}-connection-AIServices_aoai'

resource aisearch 'Microsoft.Search/searchServices@2020-03-13' existing = {
  name: aiSearchName
  scope: resourceGroup(aiSearchResourceGroupName)
}

resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: aiHubName
  location: location
  tags: tags
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // organization
    friendlyName: aiHubFriendlyName
    description: aiHubDescription

    // dependent resources
    keyVault: keyVaultId
    storageAccount: storageAccountId
    applicationInsights: applicationInsightsId
    containerRegistry: containerRegistryId
  }

  resource aiServicesConnection 'connections@2024-10-01' = {
    name: aoaiConnectionName
    properties: {
      category: 'AzureOpenAI'
      target: aiServicesTarget
      authType: 'AAD'
      isSharedToAll: true
      metadata: {
        ApiType: 'Azure'
        ResourceId: aiServicesId
      }
    }
  }

  resource hub_connection_azureai_search 'connections@2024-07-01-preview' = {
    name: acsConnectionName
    properties: {
      category: 'CognitiveSearch'
      target: 'https://${aiSearchName}.search.windows.net'
      authType: 'AAD'
      //useWorkspaceManagedIdentity: false
      isSharedToAll: true
      metadata: {
        ApiType: 'Azure'
        ResourceId: aisearch.id
        location: aisearch.location
      }
    }
  }
}

output id string = aiHub.id
output name string = aiHub.name
output aoaiConnectionName string = aoaiConnectionName
output acsConnectionName string = acsConnectionName
