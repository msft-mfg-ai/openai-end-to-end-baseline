param tags object = {}
param vnetResourceId string
param keyVaultPrivateEndpointName string
param acrPrivateEndpointName string
param openAiPrivateEndpointName string
param documentIntelligencePrivateEndpointName string
param aiSearchPrivateEndpointName string
param cosmosPrivateEndpointName string
param storageBlobPrivateEndpointName string
param storageQueuePrivateEndpointName string
param storageTablePrivateEndpointName string

param defaultAcaDomain string = ''
param acaStaticIp string = ''

module kvZone 'zone-with-a-record.bicep' = {
  name: 'kvZone'
  params: {
    zoneName: 'privatelink.vaultcore.azure.net'
    vnetResourceId: vnetResourceId
    tags: tags
    privateEndpointNames: [keyVaultPrivateEndpointName]
  }
}

module acrZone 'zone-with-a-record.bicep' = {
  name: 'acrZone'
  params: {
    zoneName: 'privatelink.azurecr.io'
    vnetResourceId: vnetResourceId
    tags: tags
    privateEndpointNames: [acrPrivateEndpointName]
  }
}

module openAiZone 'zone-with-a-record.bicep' = {
  name: 'openAiZone'
  params: {
    zoneName: 'privatelink.openai.azure.com'
    vnetResourceId: vnetResourceId
    tags: tags
    privateEndpointNames: [openAiPrivateEndpointName]
  }
}

module documentIntelligenceZone 'zone-with-a-record.bicep' = {
  name: 'docInteliZone'
  params: {
    zoneName: 'privatelink.cognitiveservices.azure.com'
    vnetResourceId: vnetResourceId
    tags: tags
    privateEndpointNames: [documentIntelligencePrivateEndpointName]
  }
}

module aiSearchZone 'zone-with-a-record.bicep' = {
  name: 'aiSearchZone'
  params: {
    zoneName: 'privatelink.search.windows.net'
    vnetResourceId: vnetResourceId
    tags: tags
    privateEndpointNames: [aiSearchPrivateEndpointName]
  }
}

module cosmosZone 'zone-with-a-record.bicep' = {
  name: 'cosmosZone'
  params: {
    zoneName: 'privatelink.documents.azure.com'
    vnetResourceId: vnetResourceId
    tags: tags
    privateEndpointNames: [cosmosPrivateEndpointName]
  }
}

module storageBlobZone 'zone-with-a-record.bicep' = {
  name: 'storageBlobZone'
  params: {
    zoneName: 'privatelink.blob.${environment().suffixes.storage}' 
    vnetResourceId: vnetResourceId
    tags: tags
    privateEndpointNames: [storageBlobPrivateEndpointName]
  }
}

module storageTableZone 'zone-with-a-record.bicep' = {
  name: 'storageTableZone'
  params: {
    zoneName: 'privatelink.table.${environment().suffixes.storage}' 
    vnetResourceId: vnetResourceId
    tags: tags
    privateEndpointNames: [storageTablePrivateEndpointName]
  }
}

module storageQueueZone 'zone-with-a-record.bicep' = {
  name: 'storageQueueZone'
  params: {
    zoneName: 'privatelink.queue.${environment().suffixes.storage}' 
    vnetResourceId: vnetResourceId
    tags: tags
    privateEndpointNames: [storageQueuePrivateEndpointName]
  }
}

// module storageFileZone 'zone-with-a-record.bicep' = {
//   name: 'storageFileZone'
//   params: {
//     zoneName: 'privatelink.file.${environment().suffixes.storage}' 
//     vnetResourceId: vnetResourceId
//     tags: tags
//     privateEndpointNames: [storagePrivateEndpointName]
//   }
// }

resource acaZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (!empty(defaultAcaDomain)) {
  name: defaultAcaDomain
  location: 'global'
  tags: tags
  properties: {}

  resource acaRecord 'A@2020-06-01' = {
    name: '*'
    properties: {
      ttl: 3600
      aRecords: [
        {
          ipv4Address: acaStaticIp
        }
      ]
    }
  }
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (!empty(defaultAcaDomain)) {
  parent: acaZone
  name: uniqueString(acaZone.id)
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetResourceId
    }
  }
}
