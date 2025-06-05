param location string = resourceGroup().location

param existingVirtualNetworkName string = ''
param existingVnetResourceGroupName string = resourceGroup().name
param newVirtualNetworkName string = ''
param vnetAddressPrefix string
//param subnet1Name string    - commented out to avoid confusion with existingVirtualNetworkName
//param subnet2Name string - commented out to avoid confusion with existingVirtualNetworkName
//param subnet1Prefix string - commented out to avoid confusion with existingVirtualNetworkName
//param subnet2Prefix string - commented out to avoid confusion with existingVirtualNetworkName

// Additional subnet name and prefix parameters for all subnets used below
param vnetAppGwSubnetName string
param vnetAppGwSubnetPrefix string
param vnetAppSeSubnetName string
param vnetAppSeSubnetPrefix string
param vnetPeSubnetName string
param vnetPeSubnetPrefix string
param vnetAgentSubnetName string
param vnetAgentSubnetPrefix string
param vnetBastionSubnetName string
param vnetBastionSubnetPrefix string
param vnetJumpboxSubnetName string
param vnetJumpboxSubnetPrefix string
param vnetTrainingSubnetName string
param vnetTrainingSubnetPrefix string
param vnetScoringSubnetName string
param vnetScoringSubnetPrefix string

var useExistingResource = !empty(existingVirtualNetworkName)

resource existingVirtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' existing = if (useExistingResource) {
  name: existingVirtualNetworkName
  scope: resourceGroup(existingVnetResourceGroupName)
  resource subnet1 'subnets' existing = {
    name: vnetAppGwSubnetName
  }
  resource subnet2 'subnets' existing = {
    name: vnetAppSeSubnetName
  }
}
module appSubnetNSG './network-security-group.bicep' = if (!useExistingResource) {
  name: 'nsg'
  params: {
    nsgName: '${newVirtualNetworkName}-${vnetAppSeSubnetName}-nsg-${location}'
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
        name: vnetAppGwSubnetName // The subnet for the Application Gateway
        properties: {
          addressPrefix: vnetAppGwSubnetPrefix // The address prefix for the Application Gateway subnet
        }
      }
      {
        // The subnet of the managed environment must be delegated to the service 'Microsoft.App/environments'
        name: vnetAppSeSubnetName // The subnet for the Container Apps Environment
        properties: {
          addressPrefix: vnetAppSeSubnetPrefix // The address prefix for the Container Apps Environment subnet
          networkSecurityGroup: {
            id: appSubnetNSG.outputs.id
          }
          delegations: [ 
            {
              name: 'environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
              // id: 'string' // Resource ID.
              // type: 'string' // Resource type.
            } 
          ] 
        }
      }
      {name: vnetPeSubnetName // The subnet for the Private Endpoints
        properties: {
          addressPrefix: vnetPeSubnetPrefix // The address prefix for the Private Endpoint subnet
        }
      }
      {name: vnetAgentSubnetName // The subnet for the Container Apps Agent Pool
        properties: {
          addressPrefix: vnetAgentSubnetPrefix // The address prefix for the Container Apps Agent Pool subnet
        }
      }
      {name: vnetAgentSubnetName // The subnet for the Container Apps Agent Pool
        properties: {
          addressPrefix: vnetAgentSubnetPrefix // The address prefix for the Container Apps Agent Pool subnet
        }
      }
      {name: vnetBastionSubnetName // The subnet for the Azure Bastion
        properties: {
          addressPrefix: vnetBastionSubnetPrefix // The address prefix for the Azure Bastion subnet
        }
      }
      {name: vnetJumpboxSubnetName // The subnet for the Jumpbox
        properties: {
          addressPrefix: vnetJumpboxSubnetPrefix // The address prefix for the Jumpbox subnet
        }
      }
      {name: vnetTrainingSubnetName // The subnet for the Training
        properties: {
          addressPrefix: vnetTrainingSubnetPrefix // The address prefix for the Training subnet
        }
      }
      {name: vnetScoringSubnetName // The subnet for the Scoring
        properties: {
          addressPrefix: vnetScoringSubnetPrefix // The address prefix for the Scoring subnet
        }
      }
    ]
  }

  resource subnet1 'subnets' existing = {
    name: vnetAppGwSubnetName
  }

  resource subnet2 'subnets' existing = {
    name: vnetAppSeSubnetName
  }
}

output vnetResourceId string = useExistingResource ? existingVirtualNetwork.id : newVirtualNetwork.id
output vnetName string = useExistingResource ? existingVirtualNetwork.name : newVirtualNetwork.name
output vnetAddressPrefix string = useExistingResource ? existingVirtualNetwork.properties.addressSpace.addressPrefixes[0] :  newVirtualNetwork.properties.addressSpace.addressPrefixes[0]
output subnet1ResourceId string = useExistingResource ? existingVirtualNetwork::subnet1.id : newVirtualNetwork::subnet1.id
output subnet2ResourceId string = useExistingResource ? existingVirtualNetwork::subnet2.id : newVirtualNetwork::subnet2.id
