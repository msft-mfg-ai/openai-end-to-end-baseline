@description('Required. Name of the Bastion host.')
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Resource ID of the subnet where the Bastion Host will be deployed.')
param subnetId string

@description('Required. Name of the Public IP resource for the Bastion Host.')
param publicIPName string

@description('Optional. The SKU of this Bastion Host.')
@allowed([
  'Basic'
  'Standard'
])
param skuName string = 'Standard'

@description('Optional. IP configuration name.')
param ipConfigurationName string = 'IpConf'

@description('Optional. Specifies if Azure Bastion host should be enabled for IP-based connection.')
param enableIPConnect bool = false

@description('Optional. Specifies if Azure Bastion host should be enabled for file copy.')
param enableFileCopy bool = true

@description('Optional. Specifies if Azure Bastion host should be enabled for Shareable Link.')
param enableShareableLink bool = false

@description('Optional. Specifies if Azure Bastion host should be enabled for Tunneling.')
param enableTunneling bool = true

@description('Optional. Tags for the resource.')
param tags object = {}

resource publicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: publicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: tags
}

resource bastion 'Microsoft.Network/bastionHosts@2023-04-01' = {
  name: name
  location: location
  sku: {
    name: skuName
  }
  properties: {
    enableTunneling: enableTunneling
    enableIpConnect: enableIPConnect
    enableFileCopy: enableFileCopy
    enableShareableLink: enableShareableLink
    ipConfigurations: [
      {
        name: ipConfigurationName
        properties: {
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
  }
  tags: tags
}

@description('The resource ID of the deployed bastion host.')
output bastionId string = bastion.id

@description('The resource group the bastion host was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The name of the deployed bastion host.')
output name string = bastion.name

@description('The location the resource was deployed into.')
output location string = bastion.location

@description('The public IP address of the bastion host.')
output publicIPAddress string = publicIP.properties.ipAddress
