// Copied from https://github.com/Azure/azure-quickstart-templates/tree/master/quickstarts/microsoft.machinelearningservices/aistudio-entraid-passthrough
// See also https://learn.microsoft.com/en-us/samples/azure-samples/azure-ai-studio-secure-bicep/azure-ai-studio-secure-bicep/
// Creates an Azure AI Hub resource with proxied endpoints for the Azure AI services provider

@description('Azure region used for the deployment of the Azure AI Hub.')
param location string

@description('Set of tags to apply to the Azure AI Hub.')
param tags object = {}

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

@description('Flag to determine if role assignments should be added to the Azure AI Hub.')
param addRoleAssignments bool = true

@description('The object ID of a Microsoft Entra ID users to be granted necessary role assignments to access the Azure AI Hub.')
param userObjectId string = ''
param userObjectType string = 'User'

// @description('The object ID of the application identity to be granted necessary role assignments to access the Azure AI Hub.')
// param managedIdentityResourceId string = ''
@description('The principal ID of the application identity to be granted necessary role assignments to access the Azure AI Hub.')
param managedIdentityPrincipalId string = ''
param managedIdentityType string = 'ServicePrincipal'

@description('Name AI Search resource')
param aiSearchName string
param aiSearchResourceGroupName string = resourceGroup().name

var aiServiceConnectionName = '${aiHubName}-connection-AIService'
var searchConnectionName  = '${aiHubName}-connection-AISearch'

resource aiSearch 'Microsoft.Search/searchServices@2020-03-13' existing = {
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
    // tried this but it keeps getting a 400 error with not other details...?
    // type: 'UserAssigned'
    // userAssignedIdentities: {
    //   '${managedIdentityResourceId}': {}
    // }
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
    //systemDatastoresAuthMode: 'identity'
  }

  resource aiHubAIServiceConnection 'connections@2024-10-01' = {
    name: aiServiceConnectionName
    properties: {
      category: 'AzureOpenAI'
      target: aiServicesTarget
      isSharedToAll: true
      authType: 'AAD'
      metadata: {
        ApiType: 'Azure'
        ResourceId: aiServicesId
      }
    }
  }
  resource aiHubSearchConnection 'connections@2024-07-01-preview' = {
    name: searchConnectionName
    properties: {
      category: 'CognitiveSearch'
      target: 'https://${aiSearchName}.search.windows.net'
      isSharedToAll: true
      authType: 'AAD'
      metadata: {
        ApiType: 'Azure'
        ResourceId: aiSearch.id
        location: aiSearch.location
      }
    }
  }
}

var roleDefinitions = loadJsonContent('../../data/roleDefinitions.json')
resource adminRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (addRoleAssignments && userObjectId != '') {
  name: guid(aiHub.id, userObjectId, 'dataScientistRole')
  scope: aiHub
  properties: {
    principalId: userObjectId
    principalType: userObjectType
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.ml.dataScientistRole)
    description: 'Permission for admin ${userObjectId} to use ${aiHubName}'
  }
}

resource applicationAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (addRoleAssignments && managedIdentityPrincipalId != '') {
  name: guid(aiHub.id, managedIdentityPrincipalId, 'dataScientistRole')
  scope: aiHub
  properties: {
    principalId: managedIdentityPrincipalId
    principalType: managedIdentityType
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.ml.dataScientistRole)
    description: 'Permission for application ${managedIdentityPrincipalId} to use ${aiHubName}'
  }
}

output id string = aiHub.id
output name string = aiHub.name
output aiServiceConnectionName string = aiServiceConnectionName
output searchConnectionName string = searchConnectionName
