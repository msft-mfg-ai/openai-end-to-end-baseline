param name string = 'add'
param keyVaultName string = ''
//  if I add in this scope, it complains about adding the policies...
//param keyVaultResourceGroupName string = resourceGroup().name
param permissions object = { secrets: [ 'get', 'list' ] }
param principalId string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
  //scope: resourceGroup(keyVaultResourceGroupName)
}

resource keyVaultAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  parent: keyVault
  name: name
  properties: {
    accessPolicies: [ {
        objectId: principalId
        tenantId: subscription().tenantId
        permissions: permissions
      } ]
  }
}
