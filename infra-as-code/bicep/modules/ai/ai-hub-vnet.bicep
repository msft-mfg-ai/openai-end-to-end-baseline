// Copied from https://github.com/Azure/azure-quickstart-templates/tree/master/quickstarts/microsoft.machinelearningservices/aistudio-network-restricted
// See also https://learn.microsoft.com/en-us/samples/azure-samples/azure-ai-studio-secure-bicep/azure-ai-studio-secure-bicep/
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

@description('Flag to determine if role assignments should be added to the Azure AI Hub.')
param addRoleAssignments bool = true

@description('The object ID of a Microsoft Entra ID users to be granted necessary role assignments to access the Azure AI Hub.')
param userObjectId string = ''

@description('The object ID of the application identity to be granted necessary role assignments to access the Azure AI Hub.')
param managedIdentityId string = ''

@description('Resource ID of the AI Search resource')
param searchId string

@description('Resource ID of the AI Search endpoint')
param searchTarget string

@description('Resource Id of the virtual network to deploy the resource into.')
param vnetResourceId string

@description('Subnet Id to deploy into.')
param subnetResourceId string

@description('Unique Suffix used for name generation')
param uniqueSuffix string

@description('SystemDatastoresAuthMode')
@allowed(['identity','accesskey'])
param systemDatastoresAuthMode string

@description('AI Service Connection Auth Mode')
@allowed(['ApiKey','AAD'])
param connectionAuthMode string

var privateEndpointName = '${aiHubName}-AIHub-PE'
var targetSubResource = ['amlworkspace']

resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-04-01-preview' = {
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

    // network settings
    provisionNetworkNow: true
    publicNetworkAccess: 'Disabled'
    managedNetwork: {
      isolationMode: 'AllowInternetOutBound'
    }
    systemDatastoresAuthMode: systemDatastoresAuthMode

    // private link settings
    sharedPrivateLinkResources: []
  }

  
  // Azure Search connection
  resource searchServiceConnection 'connections@2024-01-01-preview' = {
    name: '${aiHubName}-connection-Search'
    properties: {
      category: 'CognitiveSearch'
      target: searchTarget
      #disable-next-line BCP225
      authType: connectionAuthMode 
      isSharedToAll: true
      useWorkspaceManagedIdentity: false
      sharedUserList: []

      credentials: connectionAuthMode == 'ApiKey'
      ? {
          key: '${listAdminKeys(searchId, '2023-11-01')}'
        }
      : null

      metadata: {
        ApiType: 'Azure'
        ResourceId: searchId
      }
    }
  }

  // AI Services connection
  resource aiServicesConnection 'connections@2024-04-01-preview' = {
    name: '${aiHubName}-connection'
    properties: {
      category: 'AIServices'
      target: aiServicesTarget
      #disable-next-line BCP225
      authType: connectionAuthMode 
      isSharedToAll: true
      
      credentials: connectionAuthMode == 'ApiKey'
        ? {
            key: '${listKeys(aiServicesId, '2021-10-01')}'
          }
        : null

      metadata: {
        ApiType: 'Azure'
        ResourceId: aiServicesId
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
    principalType: 'User'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.ml.dataScientistRole)
    description: 'Permission for admin ${userObjectId} to use ${aiHubName}'
  }
}

resource applicationAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (addRoleAssignments && managedIdentityId != '') {
  name: guid(aiHub.id, managedIdentityId, 'dataScientistRole')
  scope: aiHub
  properties: {
    principalId: userObjectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.ml.dataScientistRole)
    description: 'Permission for application ${managedIdentityId} to use ${aiHubName}'
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnetResourceId
    }
    customNetworkInterfaceName: '${aiHubName}-nic-${uniqueSuffix}'
    privateLinkServiceConnections: [
      {
        name: aiHubName
        properties: {
          privateLinkServiceId: aiHub.id
          groupIds: targetSubResource
        }
      }
    ]
  }
}

resource privateLinkApi 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.api.azureml.ms'
  location: 'global'
  tags: {}
  properties: {}
}

resource privateLinkNotebooks 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.notebooks.azure.net'
  location: 'global'
  tags: {}
  properties: {}
}

resource vnetLinkApi 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateLinkApi
  name: '${uniqueString(vnetResourceId)}-api'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetResourceId
    }
    registrationEnabled: false
  }
}

resource vnetLinkNotebooks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateLinkNotebooks
  name: '${uniqueString(vnetResourceId)}-notebooks'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetResourceId
    }
    registrationEnabled: false
  }
}

resource dnsZoneGroupAiHub 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-api-azureml-ms'
        properties: {
            privateDnsZoneId: privateLinkApi.id
        }
      }
      {
        name: 'privatelink-notebooks-azure-net'
        properties: {
            privateDnsZoneId: privateLinkNotebooks.id
        }
      }
    ]
  }
  dependsOn: [
    vnetLinkApi
    vnetLinkNotebooks
  ]
}

output id string = aiHub.id
output name string = aiHub.name
output aiHubPrincipalId string = aiHub.identity.principalId
