// --------------------------------------------------------------------------------------------------------------
// Search Service
// --------------------------------------------------------------------------------------------------------------
// If you have trouble deleting this resource, you may need to manually delete the associated Shared Private Access (SPL) links first:
// $appName="XXXXXX"
// $rgName="rg-XXXXXX-dev"
// $envName="dev"
// $stAcronym="st"
// az search shared-private-link-resource delete --name link-to-storage-$appName$stAcronym$envName --service-name $appName-srch-$envName --resource-group $rgName
// az search shared-private-link-resource delete --name link-to-openai-$appName-cog-$envName --service-name $appName-srch-$envName --resource-group $rgName
// --------------------------------------------------------------------------------------------------------------
param name string = ''
param location string = resourceGroup().location
param tags object = {}

param existingSearchServiceName string = ''
param existingSearchServiceResourceGroupName string = resourceGroup().name

param sku object = {
  name: 'standard'
  //name: 'basic'
}

@description('Ip Address to allow access to the Azure Search Service')
param myIpAddress string = ''
param partitionCount int = 1
@allowed([
  'enabled'
  'disabled'
])
param publicNetworkAccess string = 'disabled'
param replicaCount int = 1

@allowed(['disabled', 'free', 'standard'])
@description('Optional. Sets options that control the availability of semantic search. This configuration is only possible for certain search SKUs in certain locations. Free Sku = disabled')
param semanticSearch string = 'standard'

param privateEndpointSubnetId string = ''
param privateEndpointName string = ''
param managedIdentityId string = ''
param disableLocalAuth bool = false
// --------------------------------------------------------------------------------------------------------------
// Variables
// --------------------------------------------------------------------------------------------------------------
var useExistingSearchService = !empty(existingSearchServiceName)
var resourceGroupName = resourceGroup().name
var searchKeySecretName = 'search-key'

// --------------------------------------------------------------------------------------------------------------
resource existingSearchService 'Microsoft.Search/searchServices@2024-06-01-preview' existing = if (useExistingSearchService) {
  name: existingSearchServiceName
  scope: resourceGroup(existingSearchServiceResourceGroupName)
}

resource search 'Microsoft.Search/searchServices@2024-06-01-preview' = if (!useExistingSearchService) {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    disableLocalAuth: disableLocalAuth
    networkRuleSet: publicNetworkAccess == 'enabled' ? {} : {
      bypass: 'AzurePortal'
      ipRules: empty(myIpAddress)
        ? []
        : [
            {
              value: myIpAddress
            }
          ]
    }
    partitionCount: partitionCount
    publicNetworkAccess: publicNetworkAccess
    replicaCount: replicaCount
    semanticSearch: semanticSearch
    authOptions: disableLocalAuth ? null : {
      aadOrApiKey: {
        aadAuthFailureMode: 'http401WithBearerChallenge'
      }
    }
  }
  sku: sku
}

resource existingPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-06-01' existing = if (useExistingSearchService && !empty(privateEndpointSubnetId)) {
  name: privateEndpointName
}
module privateEndpoint '../networking/private-endpoint.bicep' = if (!useExistingSearchService && !empty(privateEndpointSubnetId)) {
  name: '${name}-private-endpoint'
  params: {
    location: location
    privateEndpointName: privateEndpointName
    groupIds: ['searchService']
    targetResourceId: search.id
    subnetId: privateEndpointSubnetId
  }
}

// --------------------------------------------------------------------------------------------------------------
// Outputs
// --------------------------------------------------------------------------------------------------------------
output id string = useExistingSearchService ? existingSearchService.id : search.id
output resourceGroupName string = useExistingSearchService ? existingSearchServiceResourceGroupName : resourceGroupName
output subscriptionId string = subscription().subscriptionId
output name string = useExistingSearchService ? existingSearchService.name : search.name
output endpoint string = useExistingSearchService ? 'https://${existingSearchServiceName}.search.windows.net/' : 'https://${name}.search.windows.net/'
output searchKeySecretName string = searchKeySecretName
output keyVaultSecretName string = searchKeySecretName
output privateEndpointId string = empty(privateEndpointSubnetId) ? '' : useExistingSearchService ? existingPrivateEndpoint.id : privateEndpoint.outputs.privateEndpointId
output privateEndpointName string = privateEndpointName
