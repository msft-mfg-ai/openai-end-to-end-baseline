param tags object = {}
param vnetResourceId string
param zoneName string
param privateEndpointNames string[]

module zone 'private-dns.bicep' = {
  name: '${zoneName}-zone'
  params: {
    zoneName: zoneName
    vnetResourceId: vnetResourceId
    tags: tags
  }
}

resource pe 'Microsoft.Network/privateEndpoints@2023-06-01' existing = [for privateEndpointName in privateEndpointNames: {
  name: privateEndpointName
}]

resource privateEndpointDnsGroupname 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-07-01' = [for (privateEndpointName, i) in privateEndpointNames: {
  parent: pe[i]
  name: '${privateEndpointName}-dnsgroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config for ${privateEndpointName}'
        properties: {
          privateDnsZoneId: zone.outputs.id
        }
      }
    ]
  }
}]
