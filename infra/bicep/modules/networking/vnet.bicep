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
param subnetAppGwName string
param subnetAppGwPrefix string
param subnetAppSeName string
param subnetAppSePrefix string
param subnetPeName string
param subnetPePrefix string
param subnetAgentName string
param subnetAgentPrefix string
param subnetBastionName string
param subnetBastionPrefix string
param subnetJumpboxName string
param subnetJumpboxPrefix string
param subnetTrainingName string
param subnetTrainingPrefix string
param subnetScoringName string
param subnetScoringPrefix string

var useExistingResource = !empty(existingVirtualNetworkName)

resource existingVirtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' existing = if (useExistingResource) {
  name: existingVirtualNetworkName
  scope: resourceGroup(existingVnetResourceGroupName)
  resource subnet1 'subnets' existing = {
    name: subnetAppGwName
  }
  resource subnet2 'subnets' existing = {
    name: subnetAppSeName
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
module appSubnetNSG './network-security-group.bicep' = if (!useExistingResource) {
  name: 'nsg'
  params: {
    nsgName: '${newVirtualNetworkName}-${subnetAppSeName}-nsg-${location}'
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
        name: subnetAppGwName // The subnet for the Application Gateway
        properties: {
          addressPrefix: subnetAppGwPrefix // The address prefix for the Application Gateway subnet
        }
      }
      {
        // The subnet of the managed environment must be delegated to the service 'Microsoft.App/environments'
        name: subnetAppSeName // The subnet for the Container Apps Environment
        properties: {
          addressPrefix: subnetAppSePrefix // The address prefix for the Container Apps Environment subnet
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
      {name: subnetPeName // The subnet for the Private Endpoints
        properties: {
          addressPrefix: subnetPePrefix // The address prefix for the Private Endpoint subnet
        }
      }
      {name: subnetAgentName // The subnet for the Container Apps Agent Pool
        properties: {
          addressPrefix: subnetAgentPrefix // The address prefix for the Container Apps Agent Pool subnet
        }
      }
      {name: subnetAgentName // The subnet for the Container Apps Agent Pool
        properties: {
          addressPrefix: subnetAgentPrefix // The address prefix for the Container Apps Agent Pool subnet
        }
      }
      {name: subnetBastionName // The subnet for the Azure Bastion
        properties: {
          addressPrefix: subnetBastionPrefix // The address prefix for the Azure Bastion subnet
        }
      }
      {name: subnetJumpboxName // The subnet for the Jumpbox
        properties: {
          addressPrefix: subnetJumpboxPrefix // The address prefix for the Jumpbox subnet
        }
      }
      {name: subnetTrainingName // The subnet for the Training
        properties: {
          addressPrefix: subnetTrainingPrefix // The address prefix for the Training subnet
        }
      }
      {name: subnetScoringName // The subnet for the Scoring
        properties: {
          addressPrefix: subnetScoringPrefix // The address prefix for the Scoring subnet
        }
      }
    ]
  }

 // resource subnet1 'subnets' existing = {
 //   name: subnetAppGwName
 // }
//
//  resource subnet2 'subnets' existing = {
//    name: subnet2Name
//  }
  resource subnetAppGw 'subnets' existing = {
    name: subnetAppGwName  }
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
output vnetAddressPrefix string = useExistingResource ? existingVirtualNetwork.properties.addressSpace.addressPrefixes[0] :  newVirtualNetwork.properties.addressSpace.addressPrefixes[0]
//output subnet1ResourceId string = useExistingResource ? existingVirtualNetwork::subnet1.id : newVirtualNetwork::subnetAppGw.id
//output subnet2ResourceId string = useExistingResource ? existingVirtualNetwork::subnet2.id : newVirtualNetwork::subnet2.id
output subnetAppGwResourceID string = useExistingResource ? existingVirtualNetwork::subnetAppGw.id : newVirtualNetwork::subnetAppGw.id
output subnetAppSeResourceID string = useExistingResource ? existingVirtualNetwork::subnetAppSe.id : newVirtualNetwork::subnetAppSe.id  
output subnetPeResourceID string = useExistingResource ? existingVirtualNetwork::subnetPe.id : newVirtualNetwork::subnetPe.id
output subnetAgentResourceID string = useExistingResource ? existingVirtualNetwork::subnetAgent.id : newVirtualNetwork::subnetAgent.id
output subnetBastionResourceID string = useExistingResource ? existingVirtualNetwork::subnetBastion.id : newVirtualNetwork::subnetBastion.id
output subnetJumpboxResourceID string = useExistingResource ? existingVirtualNetwork::subnetJumpbox.id : newVirtualNetwork::subnetJumpbox.id
output subnetTrainingResourceID string = useExistingResource ? existingVirtualNetwork::subnetTraining.id : newVirtualNetwork::subnetTraining.id
output subnetScoringResourceID string = useExistingResource ? existingVirtualNetwork::subnetScoring.id : newVirtualNetwork::subnetScoring.id
