param existing_CogServices_Name string = ''
param existing_CogServices_ResourceGroupName string = resourceGroup().name
param name string = ''
param location string = resourceGroup().location
param pe_location string = location
param tags object = {}
//param deployments array = []
param kind string = 'OpenAI'
param publicNetworkAccess string = ''
param sku object = { name: 'S0' }
param privateEndpointSubnetId string = ''
param privateEndpointName string = ''
@description('Provide the IP address to allow access to the Azure Container Registry')
param myIpAddress string = ''
param managedIdentityId string = ''
param textEmbedding object = {}
param chatGpt_Standard object = {}
param chatGpt_Premium object = {}

// --------------------------------------------------------------------------------------------------------------
// Variables
// --------------------------------------------------------------------------------------------------------------
var resourceGroupName = resourceGroup().name
var useExistingService = !empty(existing_CogServices_Name)
var cognitiveServicesKeySecretName = 'cognitive-services-key'
var deployments = [
    {
      name: textEmbedding.DeploymentName
      model: {
        format: 'OpenAI'
        name: textEmbedding.ModelName
        version: textEmbedding.ModelVersion
      }
      sku: {
        name: 'Standard'
        capacity: textEmbedding.DeploymentCapacity
      }
    }
    {
      name: chatGpt_Standard.DeploymentName
      model: {
        format: 'OpenAI'
        name: chatGpt_Standard.ModelName
        version: chatGpt_Standard.ModelVersion
      }
      sku: {
        name: 'Standard'
        capacity: chatGpt_Standard.DeploymentCapacity
      }
    }
    {
      name: chatGpt_Premium.DeploymentName
      model: {
        format: 'OpenAI'
        name: chatGpt_Premium.ModelName
        version: chatGpt_Premium.ModelVersion
      }
      sku: {
        name: 'Standard'
        capacity: chatGpt_Premium.DeploymentCapacity
      }
    }
  ]

// --------------------------------------------------------------------------------------------------------------
resource existingAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = if (useExistingService) {
  name: existing_CogServices_Name
  scope: resourceGroup(existing_CogServices_ResourceGroupName)
}

// --------------------------------------------------------------------------------------------------------------
resource account 'Microsoft.CognitiveServices/accounts@2023-05-01' = if (!useExistingService) {
  name: name
  location: location
  tags: tags
  kind: kind
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      defaultAction: publicNetworkAccess == 'Enabled' ? 'Allow' : 'Deny'
      ipRules: empty(myIpAddress) ? [] : [
        {
          value: myIpAddress
        }
      ]
    }
    customSubDomainName: name
  }
  sku: sku
}

@batchSize(1)
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [
  for deployment in deployments: if (!useExistingService) {
    parent: account
    name: deployment.name
    properties: {
      model: deployment.model
      // // use the policy in the deployment if it exists, otherwise default to null
      // raiPolicyName: deployment.?raiPolicyName ?? null
    }
    // use the sku in the deployment if it exists, otherwise default to standard
    sku: deployment.?sku ?? { name: 'Standard', capacity: 20 }
  }
]

module privateEndpoint '../networking/private-endpoint.bicep' = if (empty(existing_CogServices_Name) && !empty(privateEndpointSubnetId)) {
  name: '${name}-private-endpoint'
  params: {
    location: pe_location
    privateEndpointName: privateEndpointName
    groupIds: ['account']
    targetResourceId: account.id
    subnetId: privateEndpointSubnetId
  }
}

// --------------------------------------------------------------------------------------------------------------
// Outputs
// --------------------------------------------------------------------------------------------------------------
output id string = !empty(existing_CogServices_Name) ? existingAccount.id : account.id
output name string = !empty(existing_CogServices_Name) ? existingAccount.name : account.name
output endpoint string = !empty(existing_CogServices_Name) ? existingAccount.properties.endpoint : account.properties.endpoint
output resourceGroupName string = !empty(existing_CogServices_Name) ? existing_CogServices_ResourceGroupName : resourceGroupName
output cognitiveServicesKeySecretName string = cognitiveServicesKeySecretName
output privateEndpointName string = privateEndpointName
output textEmbedding object = textEmbedding
output chatGpt_Standard object = chatGpt_Standard
