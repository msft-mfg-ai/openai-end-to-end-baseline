param tags object = {}
param vnetResourceId string
param dnsZonesResourceGroupName string = resourceGroup().name
param keyVaultPrivateEndpointName string = ''
param openAiPrivateEndpointName string = ''
param aiSearchPrivateEndpointName string
param storageBlobPrivateEndpointName string
param storageQueuePrivateEndpointName string
param storageTablePrivateEndpointName string
param storageFilePrivateEndpointName string = ''
param defaultAcaDomain string = ''
param acaStaticIp string = ''
param acrPrivateEndpointName string = ''
param documentIntelligencePrivateEndpointName string = ''
param cosmosPrivateEndpointName string = ''
param acaPrivateEndpointName string = ''

var deployKeyVault = !empty(keyVaultPrivateEndpointName)
var deployOpenAi = !empty(openAiPrivateEndpointName)
var deployAiSearch = !empty(aiSearchPrivateEndpointName)
var deployStorageBlob = !empty(storageBlobPrivateEndpointName)
var deployStorageQueue = !empty(storageQueuePrivateEndpointName)
var deployStorageTable = !empty(storageTablePrivateEndpointName)
var deployStorageFile = !empty(storageFilePrivateEndpointName)
var deployAcaDomain = !empty(defaultAcaDomain) && empty(acaPrivateEndpointName) // if acaPrivateEndpointName is provided, we will create a zone with A record
var deployAca = !empty(acaPrivateEndpointName)
var deployACR = !empty(acrPrivateEndpointName)
var deployDocumentIntelligence = !empty(documentIntelligencePrivateEndpointName)
var deployCosmosDb = !empty(cosmosPrivateEndpointName)

module kvZone 'zone-with-a-record.bicep' = if (deployKeyVault) {
  name: 'kvZone'
  params: {
    zoneNames: ['privatelink.vaultcore.azure.net']
    privateEndpointNames: [keyVaultPrivateEndpointName]
    vnetResourceId: vnetResourceId
    dnsZonesResourceGroupName: dnsZonesResourceGroupName
    tags: tags
  }
}

module acrZone 'zone-with-a-record.bicep' = if (deployACR) {
  name: 'acrZone'
  params: {
    zoneNames: ['privatelink.azurecr.io']
    privateEndpointNames: [acrPrivateEndpointName]
    vnetResourceId: vnetResourceId
    dnsZonesResourceGroupName: dnsZonesResourceGroupName
    tags: tags
  }
}

module openAiZone 'zone-with-a-record.bicep' = if (deployOpenAi) {
  name: 'openAiZone'
  params: {
    zoneNames: ['privatelink.openai.azure.com', 'privatelink.services.ai.azure.com', 'privatelink.cognitiveservices.azure.com']
    privateEndpointNames: [openAiPrivateEndpointName]
    vnetResourceId: vnetResourceId
    dnsZonesResourceGroupName: dnsZonesResourceGroupName
    tags: tags
  }
}

module documentIntelligenceZone 'zone-with-a-record.bicep' = if (deployDocumentIntelligence) {
  name: 'docIntelligenceZone'
  params: {
    zoneNames: ['privatelink.cognitiveservices.azure.com']
    privateEndpointNames: [documentIntelligencePrivateEndpointName]
    vnetResourceId: vnetResourceId
    dnsZonesResourceGroupName: dnsZonesResourceGroupName
    tags: tags
  }
}

module aiSearchZone 'zone-with-a-record.bicep' = if (deployAiSearch) {
  name: 'aiSearchZone'
  params: {
    zoneNames: ['privatelink.search.windows.net']
    privateEndpointNames: [aiSearchPrivateEndpointName]
    vnetResourceId: vnetResourceId
    dnsZonesResourceGroupName: dnsZonesResourceGroupName
    tags: tags
  }
}

module cosmosZone 'zone-with-a-record.bicep' = if (deployCosmosDb) {
  name: 'cosmosZone'
  params: {
    zoneNames: ['privatelink.documents.azure.com']
    privateEndpointNames: [cosmosPrivateEndpointName]
    vnetResourceId: vnetResourceId
    dnsZonesResourceGroupName: dnsZonesResourceGroupName
    tags: tags
  }
}

module storageBlobZone 'zone-with-a-record.bicep' = if (deployStorageBlob) {
  name: 'storageBlobZone'
  params: {
    zoneNames: ['privatelink.blob.${environment().suffixes.storage}']
    privateEndpointNames: [storageBlobPrivateEndpointName]
    vnetResourceId: vnetResourceId
    dnsZonesResourceGroupName: dnsZonesResourceGroupName
    tags: tags
  }
}

module storageTableZone 'zone-with-a-record.bicep' = if (deployStorageTable) {
  name: 'storageTableZone'
  params: {
    zoneNames: ['privatelink.table.${environment().suffixes.storage}']
    privateEndpointNames: [storageTablePrivateEndpointName]
    vnetResourceId: vnetResourceId
    dnsZonesResourceGroupName: dnsZonesResourceGroupName
    tags: tags
  }
}

module storageQueueZone 'zone-with-a-record.bicep' = if (deployStorageQueue) {
  name: 'storageQueueZone'
  params: {
    zoneNames: ['privatelink.queue.${environment().suffixes.storage}']
    privateEndpointNames: [storageQueuePrivateEndpointName]
    vnetResourceId: vnetResourceId
    dnsZonesResourceGroupName: dnsZonesResourceGroupName
    tags: tags
  }
}

module storageFileZone 'zone-with-a-record.bicep' = if (deployStorageFile) {
  name: 'storageFileZone'
  params: {
    zoneNames: ['privatelink.file.${environment().suffixes.storage}']
    privateEndpointNames: [storageFilePrivateEndpointName]
    vnetResourceId: vnetResourceId
    dnsZonesResourceGroupName: dnsZonesResourceGroupName
    tags: tags
  }
}

resource acaZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (deployAcaDomain) {
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

resource acaPe 'Microsoft.Network/privateEndpoints@2023-06-01' existing = {
  name: acaPrivateEndpointName
}

// privatelink.${LOCATION}.azurecontainerapps.io
module acaPrivateEndpointZone 'zone-with-a-record.bicep' = if (deployAca) {
  name: 'acaPrivateEndpointZone'
  params: {
    zoneNames: ['privatelink.${acaPe.location}.azurecontainerapps.io']
    privateEndpointNames: [acaPrivateEndpointName]
    vnetResourceId: vnetResourceId
    dnsZonesResourceGroupName: dnsZonesResourceGroupName
    tags: tags
  }
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (deployAcaDomain) {
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
