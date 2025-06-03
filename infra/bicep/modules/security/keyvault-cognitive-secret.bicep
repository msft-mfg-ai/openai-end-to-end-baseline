// --------------------------------------------------------------------------------
// This BICEP file will create KeyVault Password secret for an existing Cognitive Service
//   if existingSecretNames list is supplied: 
//     ONLY create if secretName is not in existingSecretNames list
//     OR forceSecretCreation is true
// --------------------------------------------------------------------------------
metadata description = 'Creates or updates a secret in an Azure Key Vault.'
param keyVaultName string
param secretName string
param cognitiveServiceName string
param cognitiveServiceResourceGroup string
param tags object = {}
param contentType string = 'string'
@description('The value of the secret. Provide only derived values like blob storage access, but do not hard code any secrets in your templates')
param enabledDate string = utcNow()
param expirationDate string = dateTimeAdd(utcNow(), 'P2Y')
param existingSecretNames string = ''
param forceSecretCreation bool = false
param enabled bool = true

// --------------------------------------------------------------------------------
var secretExists = contains(toLower(existingSecretNames), ';${toLower(trim(secretName))};')

// --------------------------------------------------------------------------------
resource existingResource 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = {
  scope: resourceGroup(cognitiveServiceResourceGroup)
  name: cognitiveServiceName
}
var secretValue = existingResource.listKeys().key1

resource keyVaultResource 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = if (!secretExists || forceSecretCreation) {
  name: secretName
  tags: tags
  parent: keyVaultResource
  properties: {
    attributes: {
      enabled: enabled
      exp: dateTimeToEpoch(expirationDate)
      nbf: dateTimeToEpoch(enabledDate)
    }
    contentType: contentType
    value: secretValue
  }
}

var createMessage = secretExists ? 'Secret ${secretName} already exists!' : 'Added secret ${secretName}!'
output message string = secretExists && forceSecretCreation ? 'Secret ${secretName} already exists but was recreated!' : createMessage
output secretCreated bool = !secretExists
output secretUri string = keyVaultSecret.properties.secretUri
output secretName string = secretName
