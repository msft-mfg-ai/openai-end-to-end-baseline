// ================================================================================================
// Application Gateway Module (AVM-aligned)
// ================================================================================================
// This module deploys an Azure Application Gateway following Azure Verified Module (AVM) 
// patterns and best practices for security, monitoring, and high availability
// ================================================================================================

@description('Required. Name of the Application Gateway.')
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Resource tags.')
param tags object = {}

@description('Optional. Enable/Disable usage telemetry for module.')
param enableTelemetry bool = true

@description('Required. The resource ID of an associated firewall policy.')
param firewallPolicyResourceId string

@description('Required. Subnets of the application gateway resource.')
param gatewayIPConfigurations array

@description('Required. Frontend IP addresses of the application gateway resource.')
param frontendIPConfigurations array

@description('Required. Frontend ports of the application gateway resource.')
param frontendPorts array

@description('Required. Backend address pool of the application gateway resource.')
param backendAddressPools array

@description('Required. Backend http settings of the application gateway resource.')
param backendHttpSettingsCollection array

@description('Required. Http listeners of the application gateway resource.')
param httpListeners array

@description('Required. Request routing rules of the application gateway resource.')
param requestRoutingRules array

@description('Optional. The name of the SKU for the Application Gateway.')
@allowed(['Basic', 'Standard_v2', 'WAF_v2'])
param sku string = 'WAF_v2'

@description('Optional. Lower bound on number of Application Gateway capacity.')
@minValue(0)
@maxValue(100)
param autoscaleMinCapacity int = 1

@description('Optional. Upper bound on number of Application Gateway capacity.')
@minValue(2)
@maxValue(100)
param autoscaleMaxCapacity int = 10

@description('Optional. Whether HTTP2 is enabled on the application gateway resource.')
param enableHttp2 bool = true

@description('Optional. Whether FIPS is enabled on the application gateway resource.')
param enableFips bool = false

@description('Optional. A list of availability zones denoting where the resource needs to come from.')
param zones array = [
  1
  2
  3
]

@description('Optional. SSL certificates of the application gateway resource.')
param sslCertificates array = []

@description('Optional. Diagnostic settings configuration.')
param diagnosticSettings array = []

@description('Optional. The managed identity definition for this resource.')
param managedIdentities object = {}

// ================================================================================================
// Main Application Gateway Resource
// ================================================================================================
resource applicationGateway 'Microsoft.Network/applicationGateways@2024-05-01' = {
  name: name
  location: location
  tags: tags
  identity: !empty(managedIdentities) ? {
    type: managedIdentities.?systemAssigned != null && managedIdentities.?systemAssigned ? (!empty(managedIdentities.?userAssignedResourceIds ?? {}) ? 'SystemAssigned, UserAssigned' : 'SystemAssigned') : (!empty(managedIdentities.?userAssignedResourceIds ?? {}) ? 'UserAssigned' : 'None')
    userAssignedIdentities: !empty(managedIdentities.?userAssignedResourceIds ?? {}) ? toObject(managedIdentities!.userAssignedResourceIds, key => key, key => {}) : null
  } : null
  zones: zones
  properties: {
    sku: {
      name: sku
      tier: sku
    }
    autoscaleConfiguration: {
      minCapacity: autoscaleMinCapacity
      maxCapacity: autoscaleMaxCapacity
    }
    gatewayIPConfigurations: gatewayIPConfigurations
    frontendIPConfigurations: frontendIPConfigurations
    frontendPorts: frontendPorts
    backendAddressPools: backendAddressPools
    backendHttpSettingsCollection: backendHttpSettingsCollection
    httpListeners: httpListeners
    requestRoutingRules: requestRoutingRules
    sslCertificates: sslCertificates
    firewallPolicy: {
      id: firewallPolicyResourceId
    }
    enableHttp2: enableHttp2
    enableFips: enableFips
    sslPolicy: {
      policyType: 'Custom'
      minProtocolVersion: 'TLSv1_2'
      cipherSuites: [
        'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256'
        'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384'
        'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256'
        'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384'
      ]
    }
  }
}

// ================================================================================================
// Diagnostic Settings
// ================================================================================================
resource applicationGateway_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [for (diagnosticSetting, index) in (diagnosticSettings ?? []): {
  name: diagnosticSetting.?name ?? '${name}-diagnosticSettings'
  properties: {
    storageAccountId: diagnosticSetting.?storageAccountResourceId
    workspaceId: diagnosticSetting.?workspaceResourceId
    eventHubAuthorizationRuleId: diagnosticSetting.?eventHubAuthorizationRuleResourceId
    eventHubName: diagnosticSetting.?eventHubName
    metrics: [for group in (diagnosticSetting.?metricCategories ?? [{ category: 'AllMetrics' }]): {
      category: group.category
      enabled: group.?enabled ?? true
      retentionPolicy: {
        enabled: false
        days: 0
      }
    }]
    logs: [for group in (diagnosticSetting.?logCategoriesAndGroups ?? [{ categoryGroup: 'allLogs' }]): {
      categoryGroup: group.?categoryGroup
      category: group.?category
      enabled: group.?enabled ?? true
      retentionPolicy: {
        enabled: false
        days: 0
      }
    }]
    marketplacePartnerId: diagnosticSetting.?marketplacePartnerResourceId
    logAnalyticsDestinationType: diagnosticSetting.?logAnalyticsDestinationType
  }
  scope: applicationGateway
}]

// ================================================================================================
// Telemetry (AVM requirement)
// ================================================================================================
#disable-next-line no-deployments-resources
resource avmTelemetry 'Microsoft.Resources/deployments@2024-03-01' = if (enableTelemetry) {
  name: '46d3xbcp.res.network-applicationgateway.${replace('-..--..-', '.', '-')}.${substring(uniqueString(deployment().name, location), 0, 4)}'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
      outputs: {
        telemetry: {
          type: 'String'
          value: 'For more information, see https://aka.ms/avm/TelemetryInfo'
        }
      }
    }
  }
}

// ================================================================================================
// Outputs
// ================================================================================================
@description('The resource ID of the application gateway.')
output resourceId string = applicationGateway.id

@description('The name of the application gateway.')
output name string = applicationGateway.name

@description('The resource group the application gateway was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The location the resource was deployed into.')
output location string = applicationGateway.location

@description('The backend address pools of the application gateway.')
output backendAddressPools array = applicationGateway.properties.backendAddressPools

@description('The frontend IP configurations of the application gateway.')
output frontendIPConfigurations array = applicationGateway.properties.frontendIPConfigurations
