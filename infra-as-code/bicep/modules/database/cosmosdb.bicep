// --------------------------------------------------------------------------------
// This BICEP file will create a Cosmos Database
// This expects a parameter with a list of containers/keys, something like this:
//   var cosmosContainerArray = [
//     { name: 'AgentLog', partitionKey: '/requestId' }
//     { name: 'UserDocuments', partitionKey: '/userId' }
//     { name: 'ChatTurn', partitionKey: '/chatId' }
//   ]
// --------------------------------------------------------------------------------
@description('Cosmos DB account name')
param accountName string = 'sql-${uniqueString(resourceGroup().id)}'
param existingAccountName string = ''
param existingCosmosResourceGroupName string = resourceGroup().name

@description('The name for the SQL database')
param databaseName string

@description('The collection of containers to create')
param containerArray array = []

@description('Location for the Cosmos DB account.')
param location string = resourceGroup().location

@description('Provide the IP address to allow access to the Azure Container Registry')
param myIpAddress string = ''

param publicNetworkAccess string = ''

param tags object = {}

param privateEndpointSubnetId string = ''
param privateEndpointName string = ''
param managedIdentityPrincipalId string = ''
param userPrincipalId string = ''

// --------------------------------------------------------------------------------------------------------------
// Variables
// --------------------------------------------------------------------------------------------------------------
var connectionStringSecretName = 'azure-cosmos-connection-string'
var useExistingAccount = !empty(existingAccountName)

// --------------------------------------------------------------------------------------------------------------
// Use existing Cosmos DB account
// --------------------------------------------------------------------------------------------------------------
resource existingCosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-08-15' existing = if (useExistingAccount) {
  name: existingAccountName
  scope: resourceGroup(existingCosmosResourceGroupName)
}

// --------------------------------------------------------------------------------------------------------------
// Create new Cosmos DB account
// --------------------------------------------------------------------------------------------------------------
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-08-15' = if (!useExistingAccount) {
  name: toLower(accountName)
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  properties: {
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    isVirtualNetworkFilterEnabled: false
    virtualNetworkRules: []
    disableKeyBasedMetadataWriteAccess: false
    disableLocalAuth: false
    enableFreeTier: false
    enableAnalyticalStorage: false
    createMode: 'Default'
    databaseAccountOfferType: 'Standard'
    publicNetworkAccess: publicNetworkAccess
    networkAclBypass: 'AzureServices'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
      maxIntervalInSeconds: 5
      maxStalenessPrefix: 100
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    cors: []
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
    ipRules: empty(myIpAddress)
      ? []
      : [
          {
            ipAddressOrRange: myIpAddress
          }
        ]
  }
}

resource cosmosDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-08-15' = if (!useExistingAccount) {
  parent: cosmosAccount
  name: databaseName
  tags: tags
  properties: {
    resource: {
      id: databaseName
    }
    options: {}
  }
}

resource chatContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-08-15' = [for container in containerArray: if (!useExistingAccount) {
  parent: cosmosDatabase
  name: container.Name
  tags: tags
  properties: {
    resource: {
      id: container.name
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [{ path: '/*' }]
        excludedPaths: [{ path: '/"_etag"/?' }]
      }
      partitionKey: {
        paths: [ container.partitionKey ]
        kind: 'Hash'
      }
      conflictResolutionPolicy: {
        mode: 'LastWriterWins'
        conflictResolutionPath: '/_ts'
      }
    }
    options: {}
  }
}]

module privateEndpoint '../networking/private-endpoint.bicep' = if (!useExistingAccount && !empty(privateEndpointSubnetId)) {
  name: '${accountName}-private-endpoint'
  params: {
    location: location
    privateEndpointName: privateEndpointName
    groupIds: ['Sql']
    targetResourceId: cosmosAccount.id
    subnetId: privateEndpointSubnetId
  }
}

var roleDefinitions = loadJsonContent('../../data/roleDefinitions.json')

resource cosmosDbDataContributorRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-08-15' = if (!useExistingAccount) {
  name: guid(
    resourceGroup().id,
    managedIdentityPrincipalId,
    roleDefinitions.cosmos.dataContributorRoleId,
    cosmosAccount.id
  )
  parent: cosmosAccount
  properties: {
    principalId: managedIdentityPrincipalId
    roleDefinitionId: '${resourceGroup().id}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosDatabase.name}/sqlRoleDefinitions/${roleDefinitions.cosmos.dataContributorRoleId}'
    scope: cosmosAccount.id
  }
}

resource cosmosDbUserAccessRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-08-15' = if (!useExistingAccount && userPrincipalId != '') {
  name: guid(resourceGroup().id, userPrincipalId, roleDefinitions.cosmos.dataContributorRoleId, cosmosAccount.id)
  parent: cosmosAccount
  properties: {
    principalId: userPrincipalId
    roleDefinitionId: '${resourceGroup().id}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosDatabase.name}/sqlRoleDefinitions/${roleDefinitions.cosmos.dataContributorRoleId}'
    scope: cosmosAccount.id
  }
}

// --------------------------------------------------------------------------------------------------------------
// Outputs
// --------------------------------------------------------------------------------------------------------------
output id string = useExistingAccount ? existingCosmosAccount.id : cosmosAccount.id
output name string = useExistingAccount ? existingCosmosAccount.name : cosmosAccount.name
output resourceGroupName string = useExistingAccount ? existingCosmosResourceGroupName : resourceGroup().name
output endpoint string = useExistingAccount ? existingCosmosAccount.properties.documentEndpoint : cosmosAccount.properties.documentEndpoint
output keyVaultSecretName string = connectionStringSecretName
output privateEndpointName string = privateEndpointName
output databaseName string = databaseName
output connectionStringSecretName string = connectionStringSecretName
output containerNames array = [
  for (name, i) in containerArray: {
    name: name
  }
]
