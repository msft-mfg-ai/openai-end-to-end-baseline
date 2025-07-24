// ================================================================================================
// Public IP Module for Application Gateway
// ================================================================================================
// This module deploys a Public IP address specifically configured for Application Gateway
// following best practices and security standards
// ================================================================================================

@description('Required. Name of the Public IP address.')
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Resource tags.')
param tags object = {}

@description('Optional. Public IP address allocation method.')
@allowed(['Dynamic', 'Static'])
param allocationMethod string = 'Static'

@description('Optional. Public IP address SKU.')
@allowed(['Basic', 'Standard'])
param sku string = 'Standard'

@description('Optional. Public IP address tier.')
@allowed(['Regional', 'Global'])
param tier string = 'Regional'

@description('Optional. DNS label prefix for the public IP.')
param dnsLabelPrefix string = ''

@description('Optional. Idle timeout in minutes.')
@minValue(4)
@maxValue(30)
param idleTimeoutInMinutes int = 4

@description('Optional. A list of availability zones denoting where the resource needs to come from.')
param zones array = [
  1
  2
  3
]

var supportedZoneRegions = [
  'koreacentral'
  'mexicocentral'
  'canadacentral'
  'polandcentral'
  'israelcentral'
  'francecentral'
  'qatarcentral'
  'eastasia'
  'eastus2'
  'norwayeast'
  'italynorth'
  'swedencentral'
  'southafricanorth'
  'brazilsouth'
  'germanywestcentral'
  'westus2'
  'spaincentral'
  'northeurope'
  'uksouth'
  'australiaeast'
  'uaenorth'
  'centralus'
  'switzerlandnorth'
  'indiacentral'
  'japaneast'
  'japanwest'
]

var useZones = contains(supportedZoneRegions, toLower(location))

var availabilityZones = useZones ? zones : []

//@description('Optional. Diagnostic settings configuration.')
//param diagnosticSettings array = []

// ================================================================================================
// Public IP Resource
// ================================================================================================
resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: name
  location: location
  tags: tags
  zones: availabilityZones
  sku: {
    name: sku
    tier: tier
  }
  properties: {
    publicIPAllocationMethod: allocationMethod
    idleTimeoutInMinutes: idleTimeoutInMinutes
    dnsSettings: !empty(dnsLabelPrefix) ? {
      domainNameLabel: dnsLabelPrefix
    } : null
  }
}

// // ================================================================================================
// // Diagnostic Settings (if provided)
// // ================================================================================================
// resource publicIp_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [for (diagnosticSetting, index) in (diagnosticSettings ?? []): {
//   name: diagnosticSetting.?name ?? '${name}-diagnosticSettings'
//   properties: {
//     storageAccountId: diagnosticSetting.?storageAccountResourceId
//     workspaceId: diagnosticSetting.?workspaceResourceId
//     eventHubAuthorizationRuleId: diagnosticSetting.?eventHubAuthorizationRuleResourceId
//     eventHubName: diagnosticSetting.?eventHubName
//     logs: [
//       {
//         categoryGroup: 'allLogs'
//         enabled: true
//         retentionPolicy: {
//           enabled: true
//           days: 30
//         }
//       }
//     ]
//     metrics: [
//       {
//         category: 'AllMetrics'
//         enabled: true
//         retentionPolicy: {
//           enabled: true
//           days: 30
//         }
//       }
//     ]
//   }
//   scope: publicIp
// }]

// ================================================================================================
// Outputs
// ================================================================================================
@description('The location the resource was deployed into.')
output location string = publicIp.location

@description('The name of the public IP.')
output name string = publicIp.name

@description('The resource group the public IP was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The resource ID of the public IP.')
output resourceId string = publicIp.id

@description('The public IP address value.')
output ipAddress string = publicIp.properties.ipAddress

@description('The FQDN of the public IP.')
output fqdn string = !empty(dnsLabelPrefix) ? publicIp.properties.dnsSettings.fqdn : ''

@description('The availability zones the public IP is deployed into.')
output availabilityZones array = availabilityZones
