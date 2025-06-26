// ================================================================================================
// Application Gateway WAF Policy Module (AVM-aligned)
// ================================================================================================
// This module deploys an Application Gateway Web Application Firewall (WAF) Policy
// following Azure Verified Module (AVM) patterns and best practices
// ================================================================================================

@description('Required. Name of the Application Gateway WAF policy.')
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Resource tags.')
param tags object = {}

@description('Optional. Enable/Disable usage telemetry for module.')
param enableTelemetry bool = true

@description('Required. Describes the managedRules structure.')
param managedRules object = {
  managedRuleSets: [
    {
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
      ruleGroupOverrides: []
    }
    {
      ruleSetType: 'Microsoft_BotManagerRuleSet'
      ruleSetVersion: '1.0'
    }
  ]
  exclusions: []
}

@description('Optional. The custom rules inside the policy.')
param customRules array = []

@description('Optional. The PolicySettings for policy.')
param policySettings object = {
  state: 'Enabled'
  mode: 'Prevention'
  requestBodyCheck: true
  requestBodyInspectLimitInKB: 128
  requestBodyEnforcement: true
  maxRequestBodySizeInKb: 128
  fileUploadEnforcement: true
  fileUploadLimitInMb: 100
  customBlockResponseStatusCode: 403
  customBlockResponseBody: 'VGhpcyByZXF1ZXN0IGhhcyBiZWVuIGJsb2NrZWQgYnkgdGhlIFdlYiBBcHBsaWNhdGlvbiBGaXJld2FsbC4='
  logScrubbing: {
    state: 'Enabled'
    scrubbingRules: [
      {
        matchVariable: 'RequestHeaderNames'
        selectorMatchOperator: 'Equals'
        selector: 'Authorization'
        state: 'Enabled'
      }
      {
        matchVariable: 'RequestCookieNames'
        selectorMatchOperator: 'StartsWith'
        selector: 'session'
        state: 'Enabled'
      }
    ]
  }
}

// ================================================================================================
// Telemetry (AVM pattern)
// ================================================================================================
#disable-next-line no-deployments-resources
resource avmTelemetry 'Microsoft.Resources/deployments@2024-03-01' = if (enableTelemetry) {
  name: 'avm-waf-policy-${substring(uniqueString(deployment().name, location), 0, 4)}'
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
// WAF Policy Resource
// ================================================================================================
resource wafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2024-03-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    policySettings: policySettings
    managedRules: managedRules
    customRules: customRules
  }
}

// ================================================================================================
// Outputs (AVM pattern)
// ================================================================================================
@description('The location the resource was deployed into.')
output location string = wafPolicy.location

@description('The name of the application gateway WAF policy.')
output name string = wafPolicy.name

@description('The resource group the application gateway WAF policy was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The resource ID of the application gateway WAF policy.')
output resourceId string = wafPolicy.id
