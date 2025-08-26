param privateEndpointNames string[]
param zoneNames string[] = []
param tags object = {}
param vnetResourceId string
param dnsZonesResourceGroupName string = resourceGroup().name

resource pe 'Microsoft.Network/privateEndpoints@2023-06-01' existing = [for privateEndpointName in privateEndpointNames: {
  name: privateEndpointName
}]

module zones 'private-dns.bicep' = [for zoneName in zoneNames: {
  name: '${zoneName}-zone'
  scope: resourceGroup(dnsZonesResourceGroupName)
  params: {
    zoneName: zoneName
    vnetResourceId: vnetResourceId
    tags: tags
  }
}]

resource privateEndpointDnsGroupname 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = [for (privateEndpointName, i) in privateEndpointNames: {
  name: '${privateEndpointName}-dns-group'
  parent: pe[i]
  properties: {
    privateDnsZoneConfigs: [for (z,j) in zoneNames: {
      name: '${pe[i].name} for ${z}'
      properties: {
        privateDnsZoneId: zones[j].outputs.id
      }
    }]
  }
}]
