param existing_CogServices_Name string = ''
param existing_CogServices_RG_Name string = ''
param name string = ''
param location string = resourceGroup().location
param tags object = {}
param appInsightsName string
param agentSubnetId string = ''

param publicNetworkAccess string = ''
param sku object = {
  name: 'S0'
}
param privateEndpointSubnetId string = ''
param privateEndpointName string = ''
@description('Provide the IP address to allow access to the Azure Container Registry')
param myIpAddress string = ''
param managedIdentityId string = ''
param disableLocalAuth bool = false

// --------------------------------------------------------------------------------------------------------------
// split managed identity resource ID to get the name
var identityParts = split(managedIdentityId, '/')
// get the name of the managed identity
var managedIdentityName = length(identityParts) > 0 ? identityParts[length(identityParts) - 1] : ''

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' existing = if (!empty(managedIdentityName)) {
  name: managedIdentityName
}

// --------------------------------------------------------------------------------------------------------------
// Variables
// --------------------------------------------------------------------------------------------------------------
var resourceGroupName = resourceGroup().name
var useExistingService = !empty(existing_CogServices_Name)
var deployInVNET = !empty(privateEndpointSubnetId)
var cognitiveServicesKeySecretName = 'cognitive-services-key'

param gpt41Deployment aiModelTDeploymentType?
param deployments aiModelTDeploymentType[] = []

@export()
type aiModelTDeploymentType = {
  @description('The name of the deployment')
  name: string
  properties: {
    model: {
      @description('The name of the model - often the same as the deployment name')
      name: string
      @description('The version of the model, e.g. "2024-11-20" or "0125"')
      version: string
      format: 'OpenAI'
    }
  }
  sku: {
    name: 'Standard' | 'GlobalStandard'
    capacity: int
  }?
}

// --------------------------------------------------------------------------------------------------------------
resource existingAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = if (useExistingService) {
  scope: resourceGroup(existing_CogServices_RG_Name)
  name: existing_CogServices_Name
}

// --------------------------------------------------------------------------------------------------------------
resource account 'Microsoft.CognitiveServices/accounts@2025-06-01' = if (!useExistingService) {
  name: name
  location: location
  tags: tags
  kind: 'AIServices'
  identity: !empty(managedIdentityId)
    ? {
        type: 'UserAssigned'
        userAssignedIdentities: {
          '${managedIdentityId}': {}
        }
      }
    : {
        type: 'SystemAssigned'
      }
  properties: {
    // required to work in AI Foundry
    allowProjectManagement: true
    publicNetworkAccess: publicNetworkAccess
    disableLocalAuth: disableLocalAuth
    networkAcls: {
      bypass: 'AzureServices'

      defaultAction: empty(myIpAddress) ? 'Allow' : 'Deny'
      ipRules: empty(myIpAddress)
        ? []
        : [
            {
              value: myIpAddress
            }
          ]
      virtualNetworkRules: []
    }
    networkInjections: (!empty(agentSubnetId)
      ? [
          {
            scenario: 'agent'
            subnetArmId: agentSubnetId
            useMicrosoftManagedNetwork: false
          }
        ]
      : null)
    customSubDomainName: toLower('${(name)}')
  }
  sku: sku
}

@batchSize(1)
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = [
  for deployment in union(deployments, empty(gpt41Deployment) ? [] : [gpt41Deployment]): if (!useExistingService) {
    parent: account
    name: deployment.name
    properties: deployment.properties
    // use the sku in the deployment if it exists, otherwise default to standard
    sku: deployment.?sku ?? { name: 'Standard', capacity: 20 }
  }
]

module privateEndpoint '../networking/private-endpoint.bicep' = if (deployInVNET && !useExistingService) {
  name: '${name}-private-endpoint'
  dependsOn: [deployment]
  params: {
    tags: tags
    location: location
    privateEndpointName: privateEndpointName
    groupIds: ['account']
    targetResourceId: account.id
    subnetId: privateEndpointSubnetId
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
  scope: resourceGroup()
}

// Creates the Azure Foundry connection Application Insights
resource connection 'Microsoft.CognitiveServices/accounts/connections@2025-04-01-preview' = {
  name: 'applicationInsights'
  parent: account
  dependsOn: [deployment]
  properties: {
    category: 'AppInsights'
    //group: 'ServicesAndApps'  // read-only...
    target: appInsights.id
    authType: 'ApiKey'
    isSharedToAll: true
    //isDefault: true  // not valid property
    credentials: {
      key: appInsights.properties.InstrumentationKey
    }
    metadata: {
      ApiType: 'Azure'
      ResourceId: appInsights.id
    }
  }
}

// --------------------------------------------------------------------------------------------------------------
// Outputs
// --------------------------------------------------------------------------------------------------------------
output id string = useExistingService ? existingAccount.id : account.id
output name string = useExistingService ? existingAccount.name : account.name
output endpoint string = useExistingService ? existingAccount!.properties.endpoint : account!.properties.endpoint
output resourceGroupName string = useExistingService ? existing_CogServices_RG_Name : resourceGroupName
output cognitiveServicesKeySecretName string = cognitiveServicesKeySecretName

output chatGpt41Deployed aiModelTDeploymentType? = gpt41Deployment
output privateEndpointName string = deployInVNET && !useExistingService
  ? privateEndpoint!.outputs.privateEndpointName
  : ''
output accountPrincipalId string = empty(managedIdentityId)
  ? (useExistingService ? (existingAccount.?identity.principalId ?? '') : account.?identity.principalId ?? '')
  : (useExistingService ? '' : identity!.properties.principalId)
