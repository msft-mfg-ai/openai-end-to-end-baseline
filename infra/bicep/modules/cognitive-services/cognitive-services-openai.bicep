param location string = resourceGroup().location
param name string
param commonTags object = {}
param roleAssignments array = []

resource cognitiveServicesAccount 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' = {
  name: name
  location: location
  kind: 'AIServices'
  properties: {
    allowProjectManagement: true
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
  }
  sku: {
    name: 'S0'
  }
  tags: commonTags
  identity: {
    type: 'SystemAssigned'
  }
  
}

resource roleAssignmentsResource 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for roleAssignment in roleAssignments: if (length(roleAssignment) > 0) {
    name: guid(roleAssignment.principalId, roleAssignment.roleDefinitionId, cognitiveServicesAccount.id)
    scope: cognitiveServicesAccount
    properties: {
      roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleAssignment.roleDefinitionId)
      principalId: roleAssignment.principalId
      principalType: 'ServicePrincipal'
    }
  }
]

output resourceId string = cognitiveServicesAccount.id
output endpoint string = cognitiveServicesAccount.properties.endpoint
output name string = cognitiveServicesAccount.name
output kind string = cognitiveServicesAccount.kind
output principalId string = cognitiveServicesAccount.identity.principalId
