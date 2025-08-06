param name string = ''
param location string = resourceGroup().location
param tags object = {}

param existingStorageAccountName string = ''

param publicNetworkAccess bool = false
param privateEndpointSubnetId string = ''
param privateEndpointBlobName string = ''
param privateEndpointQueueName string = ''
param privateEndpointTableName string = ''
@description('Provide the IP address to allow access to the Azure Container Registry')
param myIpAddress string = ''

param containers string[] = []
param resourcesWithAccess object[] = []
param kind string = 'StorageV2'
param minimumTlsVersion string = 'TLS1_2'
param sku object = { name: 'Standard_LRS' }
param allowSharedKeyAccess bool = true

// --------------------------------------------------------------------------------------------------------------
// Variables
// --------------------------------------------------------------------------------------------------------------
var useExistingStorageAccount = !empty(existingStorageAccountName)
var storageAccountConnectionStringSecretName = 'storage-account-connection-string'

// --------------------------------------------------------------------------------------------------------------
// If using existing storage account, just add the missing containers
// --------------------------------------------------------------------------------------------------------------
resource existingStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = if (useExistingStorageAccount) {
  name: existingStorageAccountName
}
resource existingStorageAccountBlobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = if (useExistingStorageAccount && !empty(containers)) {
  parent: existingStorageAccount
  name: 'default'
}

resource storageAccountBlobContainerResource 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = [
  for container in containers: if (useExistingStorageAccount) {
    parent: existingStorageAccountBlobServices
    name: container
    properties: {
      publicAccess: 'None'
    }
  }
]

// --------------------------------------------------------------------------------------------------------------
// If creating the storage account...
// --------------------------------------------------------------------------------------------------------------
resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = if (!useExistingStorageAccount) {
  name: name
  location: location
  tags: tags
  kind: kind
  sku: sku
  properties: {
    minimumTlsVersion: minimumTlsVersion
    allowBlobPublicAccess: false
    publicNetworkAccess: publicNetworkAccess ? 'Enabled' : 'Disabled' // this needs to be 'Enabled' for 'Enabled from selected virtual networks and IP addresses'
    supportsHttpsTrafficOnly: true
    allowSharedKeyAccess: allowSharedKeyAccess
    networkAcls: {
      bypass: 'AzureServices'
      resourceAccessRules: resourcesWithAccess
      defaultAction: 'Deny' // publicNetworkAccess ? 'Allow' : 'Deny'
      ipRules: empty(myIpAddress)
        ? []
        : [
            {
              value: myIpAddress
            }
          ]
    }
  }

  resource blobServices 'blobServices' = if (!empty(containers)) {
    name: 'default'
    resource container 'containers' = [
      for container in containers: {
        name: container
        properties: {
          publicAccess: 'None'
        }
      }
    ]
  }
}

module privateEndpointBlob '../networking/private-endpoint.bicep' = if (!useExistingStorageAccount && !empty(privateEndpointSubnetId)) {
  name: '${name}-blob-private-endpoint'
  params: {
    location: location
    privateEndpointName: privateEndpointBlobName
    groupIds: [
      'blob'
    ]
    targetResourceId: storage.id
    subnetId: privateEndpointSubnetId
  }
}

module privateEndpointTable '../networking/private-endpoint.bicep' = if (!useExistingStorageAccount && !empty(privateEndpointSubnetId)) {
  name: '${name}-table-private-endpoint'
  params: {
    location: location
    privateEndpointName: privateEndpointTableName
    groupIds: [
      'table'
    ]
    targetResourceId: storage.id
    subnetId: privateEndpointSubnetId
  }
}

module privateEndpointQueue '../networking/private-endpoint.bicep' = if (!useExistingStorageAccount && !empty(privateEndpointSubnetId)) {
  name: '${name}-queue-private-endpoint'
  params: {
    location: location
    privateEndpointName: privateEndpointQueueName
    groupIds: [
      'queue'
    ]
    targetResourceId: storage.id
    subnetId: privateEndpointSubnetId
  }
}

// --------------------------------------------------------------------------------------------------------------
// Outputs
// --------------------------------------------------------------------------------------------------------------
output name string = useExistingStorageAccount ? existingStorageAccount.name : storage.name
output id string = useExistingStorageAccount ? existingStorageAccount.id : storage.id
// assumption: the resource group for the storage account is the same as the one where this module is deployed
output resourceGroupName string = resourceGroup().name
output subscriptionId string = subscription().subscriptionId

output primaryEndpoints object = useExistingStorageAccount ? existingStorageAccount.properties.primaryEndpoints : storage.properties.primaryEndpoints
output containerNames array = [
  for (name, i) in containers: useExistingStorageAccount ? null : {
    name: name
    url: useExistingStorageAccount ? '${existingStorageAccount.properties.primaryEndpoints.blob}/${name}' : '${storage.properties.primaryEndpoints.blob}/${name}'
  }
]
output privateEndpointBlobName string = privateEndpointBlobName
output privateEndpointTableName string = privateEndpointTableName
output privateEndpointQueueName string = privateEndpointQueueName
output storageAccountConnectionStringSecretName string = storageAccountConnectionStringSecretName
