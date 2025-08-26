param location string = resourceGroup().location

param existingVirtualNetworkName string = ''
param existingVnetResourceGroupName string = resourceGroup().name
param newVirtualNetworkName string = ''
param vnetAddressPrefix string?
//param subnet1Name string    - commented out to avoid confusion with existingVirtualNetworkName
//param subnet2Name string - commented out to avoid confusion with existingVirtualNetworkName
//param subnet1Prefix string? - commented out to avoid confusion with existingVirtualNetworkName
//param subnet2Prefix string? - commented out to avoid confusion with existingVirtualNetworkName

// Additional subnet name and prefix parameters for all subnets used below
param subnetAppGwName string
param subnetAppGwPrefix string?
param subnetAppSeName string
param subnetAppSePrefix string?
param subnetPeName string
param subnetPePrefix string?
param subnetAgentName string
param subnetAgentPrefix string?
param subnetBastionName string
param subnetBastionPrefix string?
param subnetJumpboxName string
param subnetJumpboxPrefix string?
param subnetTrainingName string
param subnetTrainingPrefix string?
param subnetScoringName string
param subnetScoringPrefix string?
param vnetNsgName string = '${newVirtualNetworkName}-${subnetAppSeName}-nsg-${location}'

var useExistingResource = !empty(existingVirtualNetworkName)

resource existingVirtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' existing = if (useExistingResource) {
  name: existingVirtualNetworkName
  scope: resourceGroup(existingVnetResourceGroupName)
  resource subnetAppGw 'subnets' existing = {
    name: subnetAppGwName
  }
  resource subnetAppSe 'subnets' existing = {
    name: subnetAppSeName
  }
  resource subnetPe 'subnets' existing = {
    name: subnetPeName
  }
  resource subnetAgent 'subnets' existing = {
    name: subnetAgentName
  }
  resource subnetBastion 'subnets' existing = {
    name: subnetBastionName
  }
  resource subnetJumpbox 'subnets' existing = {
    name: subnetJumpboxName
  }
  resource subnetTraining 'subnets' existing = {
    name: subnetTrainingName
  }
  resource subnetScoring 'subnets' existing = {
    name: subnetScoringName
  }
}
module appSubnetNSG './network-security-group.bicep' = if (!useExistingResource) {
  name: 'nsg'
  params: {
    nsgName: vnetNsgName
    location: location
  }
}

resource newVirtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' = if (!useExistingResource) {
  name: newVirtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetAppGwName
        properties: {
          addressPrefix: subnetAppGwPrefix
        }
      }
      {
        name: subnetPeName
        properties: {
          addressPrefix: subnetPePrefix
          // The subnet of the private endpoint must be delegated to the service 'Microsoft.Network/privateEndpoints'
        }
      }
      {
        name: subnetAgentName
        properties: {
          addressPrefix: subnetAgentPrefix
          delegations: [
            {
              name: 'Microsoft.app/environments'
              properties: {
                serviceName: 'Microsoft.app/environments'
              }
            }
          ]
        }
      }
      {
        name: subnetBastionName
        properties: {
          addressPrefix: subnetBastionPrefix
          // The subnet of the bastion host must be named 'AzureBastionSubnet'
          // and must have a /27 or larger prefix
        }
      }
      {
        name: subnetJumpboxName
        properties: {
          addressPrefix: subnetJumpboxPrefix
        }
      }
      {
        name: subnetTrainingName
        properties: {
          addressPrefix: subnetTrainingPrefix
        }
      }
      {
        name: subnetScoringName
        properties: {
          addressPrefix: subnetScoringPrefix
        }
      }
      {
        // The subnet of the managed environment must be delegated to the service 'Microsoft.App/environments'
        name: subnetAppSeName
        properties: {
          addressPrefix: subnetAppSePrefix
          networkSecurityGroup: {
            id: appSubnetNSG.outputs.id
          }
          delegations: [
            {
              name: 'Microsoft.App/environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
              // id: 'string' // Resource ID.
              // type: 'string' // Resource type.
            }
          ]
        }
      }
    ]
  }

  resource subnetAppGw 'subnets' existing = {
    name: subnetAppGwName
  }

  resource subnetAppSe 'subnets' existing = {
    name: subnetAppSeName
  }
  resource subnetPe 'subnets' existing = {
    name: subnetPeName
  }
  resource subnetAgent 'subnets' existing = {
    name: subnetAgentName
  }
  resource subnetBastion 'subnets' existing = {
    name: subnetBastionName
  }
  resource subnetJumpbox 'subnets' existing = {
    name: subnetJumpboxName
  }
  resource subnetTraining 'subnets' existing = {
    name: subnetTrainingName
  }
  resource subnetScoring 'subnets' existing = {
    name: subnetScoringName
  }
}

output vnetResourceId string = useExistingResource ? existingVirtualNetwork.id : newVirtualNetwork.id
output vnetName string = useExistingResource ? existingVirtualNetwork.name : newVirtualNetwork.name
output subnetAppGwResourceID string = useExistingResource
  ? existingVirtualNetwork::subnetAppGw.id
  : newVirtualNetwork::subnetAppGw.id
output subnetAppSeResourceID string = useExistingResource
  ? existingVirtualNetwork::subnetAppSe.id
  : newVirtualNetwork::subnetAppSe.id
output subnetPeResourceID string = useExistingResource
  ? existingVirtualNetwork::subnetPe.id
  : newVirtualNetwork::subnetPe.id
output subnetAgentResourceID string = useExistingResource
  ? existingVirtualNetwork::subnetAgent.id
  : newVirtualNetwork::subnetAgent.id
output subnetBastionResourceID string = useExistingResource
  ? existingVirtualNetwork::subnetBastion.id
  : newVirtualNetwork::subnetBastion.id
output subnetJumpboxResourceID string = useExistingResource
  ? existingVirtualNetwork::subnetJumpbox.id
  : newVirtualNetwork::subnetJumpbox.id
output subnetTrainingResourceID string = useExistingResource
  ? existingVirtualNetwork::subnetTraining.id
  : newVirtualNetwork::subnetTraining.id
output subnetScoringResourceID string = useExistingResource
  ? existingVirtualNetwork::subnetScoring.id
  : newVirtualNetwork::subnetScoring.id
output vnetAddressPrefix string? = useExistingResource
  ? existingVirtualNetwork.properties.addressSpace.addressPrefixes[0]
  : newVirtualNetwork.properties.addressSpace.addressPrefixes[0]
