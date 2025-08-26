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

@description('Sessions database name')
param sessionsDatabaseName string = ''

@description('The collection of containers to create')
param containerArray containerType[] = []

@description('The collection of containers to create in sessions database')
param sessionContainerArray containerType[] = []

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
param disableKeys bool = false

@export()
type containerType = {
  name: string
  partitionKey: string
}
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
    disableKeyBasedMetadataWriteAccess: disableKeys
    disableLocalAuth: disableKeys
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

resource sessionsCosmosDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-08-15' = if (!useExistingAccount && !empty(sessionsDatabaseName)) {
  parent: cosmosAccount
  name: sessionsDatabaseName
  tags: tags
  properties: {
    resource: {
      id: sessionsDatabaseName
    }
    options: {}
  }
}

resource sessionsContainers 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-08-15' = [
  for container in sessionContainerArray: if (!useExistingAccount) {
    parent: sessionsCosmosDatabase
    name: container.name
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
          paths: [container.partitionKey]
          kind: 'Hash'
        }
        conflictResolutionPolicy: {
          mode: 'LastWriterWins'
          conflictResolutionPath: '/_ts'
        }
      }
      options: {}
    }
  }
]

resource chatContainers 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-08-15' = [
  for container in containerArray: if (!useExistingAccount) {
    parent: cosmosDatabase
    name: container.name
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
          paths: [container.partitionKey]
          kind: 'Hash'
        }
        conflictResolutionPolicy: {
          mode: 'LastWriterWins'
          conflictResolutionPath: '/_ts'
        }
      }
      options: {}
    }
  }
]

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

resource cosmosDBOperatorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: roleDefinitions.cosmos.operatorRoleId
  scope: resourceGroup()
}

resource cosmosDBOperatorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!useExistingAccount) {
  scope: cosmosAccount
  name: guid(managedIdentityPrincipalId, cosmosDBOperatorRole.id, cosmosAccount.id)
  properties: {
    principalId: managedIdentityPrincipalId
    roleDefinitionId: cosmosDBOperatorRole.id
    principalType: 'ServicePrincipal'
  }
}

resource cosmosDBOperatorRoleAssignmentForUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!useExistingAccount && !empty(userPrincipalId)) {
  scope: cosmosAccount
  name: guid(userPrincipalId, cosmosDBOperatorRole.id, cosmosAccount.id)
  properties: {
    principalId: userPrincipalId
    roleDefinitionId: cosmosDBOperatorRole.id
    principalType: 'User'
  }
}

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

resource cosmosDbUserAccessRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-08-15' = if (!useExistingAccount && !empty(userPrincipalId)) {
  name: guid(resourceGroup().id, userPrincipalId, roleDefinitions.cosmos.dataContributorRoleId, cosmosAccount.id)
  parent: cosmosAccount
  properties: {
    principalId: userPrincipalId
    roleDefinitionId: '${resourceGroup().id}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosDatabase.name}/sqlRoleDefinitions/${roleDefinitions.cosmos.dataContributorRoleId}'
    scope: cosmosAccount.id
  }
}

var sessionContainerIds = [
  for container in sessionContainerArray: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosAccount.name}/dbs/${sessionsDatabaseName}/colls/${container.name}'
]
var chatContainerIds = [
  for container in containerArray: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosAccount.name}/dbs/${databaseName}/colls/${container.name}'
]

resource containerRoleAssignmentUserContainer 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2022-05-15' = [
  for container in union(chatContainerIds, sessionContainerIds): if (!useExistingAccount) {
  parent: cosmosAccount
  name: guid(container, roleDefinitions.cosmos.dataContributorRoleId, managedIdentityPrincipalId)
  properties: {
    principalId: managedIdentityPrincipalId
    roleDefinitionId: '${resourceGroup().id}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosDatabase.name}/sqlRoleDefinitions/${roleDefinitions.cosmos.dataContributorRoleId}'
    scope: container
  }
  dependsOn: [
    sessionsContainers
    chatContainers
  ]
}]

// --------------------------------------------------------------------------------------------------------------
// Outputs
// --------------------------------------------------------------------------------------------------------------
output id string = useExistingAccount ? existingCosmosAccount.id : cosmosAccount.id
output name string = useExistingAccount ? existingCosmosAccount.name : cosmosAccount.name
output resourceGroupName string = useExistingAccount ? existingCosmosResourceGroupName : resourceGroup().name
output subscriptionId string = subscription().subscriptionId
output endpoint string = useExistingAccount
  ? existingCosmosAccount.properties.documentEndpoint
  : cosmosAccount.properties.documentEndpoint
output keyVaultSecretName string = connectionStringSecretName
output privateEndpointName string = privateEndpointName
output databaseName string = databaseName
output connectionStringSecretName string = connectionStringSecretName
output containerNames array = [
  for (name, i) in containerArray: {
    name: name
  }
]
