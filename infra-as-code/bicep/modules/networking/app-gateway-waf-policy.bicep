@description('The name of the WAF policy to create')
param wafPolicyName string

@description('The Azure region where the WAF policy will be created')
param location string

@description('The tags to associate with the WAF policy')
param tags object

@description('The WAF mode to use')
@allowed([ 'Prevention', 'Detection' ])
param wafMode string

@description('The IP ranges to allow access from the InRiver application')
param inRiverIpRanges string[]

resource wafpol 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2023-11-01' = {
  name: wafPolicyName
  location: location
  tags: tags
  properties: {
    customRules: [
      {
        name: 'AllowOnlyInRiverIpRanges'
        priority: 5
        ruleType: 'MatchRule'
        action: 'Block'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RemoteAddr'
              }
            ]
            operator: 'IPMatch'
            negationConditon: true
            matchValues: inRiverIpRanges
          }
        ]
      }
    ]
    policySettings: {
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
      state: 'Enabled'
      mode: wafMode
      requestBodyInspectLimitInKB: 128
      fileUploadEnforcement: true
      requestBodyEnforcement: true
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
          ruleGroupOverrides: [
            {
              ruleGroupName: 'REQUEST-920-PROTOCOL-ENFORCEMENT'
              rules: [
                {
                  ruleId: '920230'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '920320'
                  state: 'Enabled'
                  action: 'Log'
                }
              ]
            }
            {
              ruleGroupName: 'REQUEST-942-APPLICATION-ATTACK-SQLI'
              rules: [
                {
                  ruleId: '942420'
                  state: 'Enabled'
                  action: 'Log'
                }
              ]
            }
          ]
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.0'
        }
      ]
    }
  }
}

output id string = wafpol.id
