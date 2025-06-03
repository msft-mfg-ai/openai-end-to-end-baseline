@description('The name of the Application Gateway that will be created')
param appGatewayName string

@description('The Azure region where the Application Gateway will be created')
param location string

@description('The resource ID of the subnet where the Application Gateway will be deployed')
param subnetResourceId string

@description('The name of the existing public IP address that will be used for the Application Gateway')
param appGatewayPublicIpName string

@description('The resource ID of the Log Analytics workspace where diagnostics logs will be sent')
param logAnalyticsWorkspaceResourceId string

@description('The name of the Key Vault where the Application Gateway will store its SSL certificates')
param keyVaultName string

@description('The private IP address for the Application Gateway private listener')
param internalGatewayHostPrivateIp string

@description('The minimum capacity for the Application Gateway autoscale configuration')
param minAppGatewayCapacity int

@description('The maximum capacity for the Application Gateway autoscale configuration')
param maxAppGatewayCapacity int

@description('The tags to apply to the Application Gateway resource')
param tags object = {}

@description('The host name for the internal endpoint')
param internalEndpointHostName string

@description('The host name for the external endpoint')
param externalEndpointHostName string

@description('The Key Vault URI of the TLS certificate for the internal endpoint')
param internalEndpointTlsCertificateId string

@description('The Key Vault URI of the TLS certificate for the external endpoint')
param exteralEndpointTlsCertificateId string

@description('The resource ID of the WAF policy that will be associated with the Application Gateway')
param wafPolicyResourceId string

@description('The maximum timeout in seconds for the backend to respond to a request')
param backendMaxTimeoutSeconds int

var internalHttpsListenerName = 'internalGatewayHttpsListener'
var externalHttpsListenerName = 'externalHttpsListener'
var apimFrontEndPort = 'https_443'
var appGatewayFrontendIp = 'appGatewayFrontendIp'
var internalSslCertName = 'internalSslCert'
var externalSslCertName = 'externalSslCert'
var publicFrontEndIpConfiguration = 'appGatewayPublicFrontendIp'
var internalHealthProbeName = 'internalGatewayProbe'
var externalHealthProbeName = 'externalHealthProbe'
var internalBackendSettingsName = 'internalGatewayBackendSettings'
var externalBackendSettingsName = 'externalBackendSettings'
var internalBackendAddressPoolName = 'internalGatewayBackendAddressPool'
var externalBackendAddressPoolName = 'externalBackendAddressPool'
var internalHttpsRuleName = 'internalGatewayHttpsRule'
var externalHttpsRuleName = 'externalGatewayHttpsRule'

var uamiName = '${appGatewayName}-uami'
var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'
var apimStatusPath = '/status-0123456789abcdef'

resource kvSecretUser 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: keyVaultSecretsUserRoleId
  scope: resourceGroup()
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
  scope: resourceGroup()
}

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: uamiName
  tags: tags
  location: location
}

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(uami.id, kv.id, kvSecretUser.id)
  scope: kv
  properties: {
    principalId: uami.properties.principalId
    roleDefinitionId: kvSecretUser.id
    principalType: 'ServicePrincipal'
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2023-11-01' existing = {
  name: appGatewayPublicIpName
  scope: resourceGroup()
}

resource appGw 'Microsoft.Network/applicationGateways@2023-11-01' = {
  name: appGatewayName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
  properties: {
    autoscaleConfiguration: {
      minCapacity: minAppGatewayCapacity
      maxCapacity: maxAppGatewayCapacity
    }
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: subnetResourceId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIp'
        properties: {
          privateIPAddress: internalGatewayHostPrivateIp
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnetResourceId
          }
        }
      }
      {
        name: publicFrontEndIpConfiguration
        properties: {
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: apimFrontEndPort
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: internalBackendAddressPoolName
        properties: {
          backendAddresses: [
            {
              fqdn: internalEndpointHostName
            }
          ]
        }
      }
      {
        name: externalBackendAddressPoolName
        properties: {
          backendAddresses: [
            {
              fqdn: externalEndpointHostName
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: internalBackendSettingsName
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: backendMaxTimeoutSeconds
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, internalHealthProbeName)
          }
        }
      }
      {
        name: externalBackendSettingsName
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: backendMaxTimeoutSeconds
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, externalHealthProbeName)
          }
        }
      }
    ]
    httpListeners: [
      {
        name: internalHttpsListenerName
        properties: {
          hostName: internalEndpointHostName
          frontendIPConfiguration: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendIPConfigurations',
              appGatewayName,
              appGatewayFrontendIp
            )
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, apimFrontEndPort)
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGatewayName, internalSslCertName)
          }
        }
      }
      {
        name: externalHttpsListenerName
        properties: {
          hostName: externalEndpointHostName
          frontendIPConfiguration: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendIPConfigurations',
              appGatewayName,
              publicFrontEndIpConfiguration
            )
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, apimFrontEndPort)
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGatewayName, externalSslCertName)
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: internalHttpsRuleName
        properties: {
          priority: 4
          ruleType: 'Basic'
          httpListener: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/httpListeners',
              appGatewayName,
              internalHttpsListenerName
            )
          }
          backendAddressPool: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendAddressPools',
              appGatewayName,
              internalBackendAddressPoolName
            )
          }
          backendHttpSettings: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
              appGatewayName,
              internalBackendSettingsName
            )
          }
        }
      }
      {
        name: externalHttpsRuleName
        properties: {
          priority: 5
          ruleType: 'Basic'
          httpListener: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/httpListeners',
              appGatewayName,
              externalHttpsListenerName
            )
          }
          backendAddressPool: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendAddressPools',
              appGatewayName,
              externalBackendAddressPoolName
            )
          }
          backendHttpSettings: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
              appGatewayName,
              externalBackendSettingsName
            )
          }
        }
      }
    ]
    probes: [
      {
        name: internalHealthProbeName
        properties: {
          protocol: 'Https'
          pickHostNameFromBackendHttpSettings: false
          host: internalEndpointHostName
          path: apimStatusPath
          interval: 30
          timeout: 120
          unhealthyThreshold: 3
          match: {
            statusCodes: [
              '200-399'
            ]
          
          }
        }
      }
      {
        name: externalHealthProbeName
        properties: {
          protocol: 'Https'
          pickHostNameFromBackendHttpSettings: false
          host: externalEndpointHostName
          path: apimStatusPath
          interval: 30
          timeout: 120
          unhealthyThreshold: 3
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: internalSslCertName
        properties: {
          keyVaultSecretId: internalEndpointTlsCertificateId
        }
      }
      {
        name: externalSslCertName
        properties: {
          keyVaultSecretId: exteralEndpointTlsCertificateId
        }
      }
    ]
    sslPolicy: {
      policyType: 'Predefined'
      policyName: 'AppGwSslPolicy20220101S'
    }
    forceFirewallPolicyAssociation: true
    firewallPolicy: {
      id: wafPolicyResourceId
    }
  }
  zones: ['1', '2', '3']
}

resource diags 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'laws'
  scope: appGw
  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}

output id string = appGw.id
output name string = appGw.name
