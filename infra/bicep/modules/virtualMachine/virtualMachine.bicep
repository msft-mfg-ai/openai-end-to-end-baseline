@description('Name of the Virtual Machine')
param vm_name string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Admin username for the VM')
param admin_username string

@secure()
@description('Admin password for the VM')
param admin_password string

@description('Virtual Network resource ID')
param vnet_id string

@description('Subnet name within the Virtual Network')
param subnet_name string

@description('VM size')
param vm_size string = 'Standard_D4s_v5'

@description('OS disk size in GB')
param os_disk_size_gb int = 128

@description('Tags to apply to resources')
param tags object = {}

var nic_name = '${vm_name}-nic'
var pip_name = '${vm_name}-pip'
var os_disk_name = '${vm_name}-osdisk'
var nsg_name = '${vm_name}-nsg'

resource publicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: pip_name
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: toLower('${vm_name}-dns')
    }
  }
  tags: tags
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: nsg_name
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
  tags: tags
}

resource nic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: nic_name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${vnet_id}/subnets/${subnet_name}'
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
  tags: tags
}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vm_name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vm_size
    }
    osProfile: {
      computerName: vm_name
      adminUsername: admin_username
      adminPassword: admin_password
      windowsConfiguration: {
        enableAutomaticUpdates: true
      }
    }
    storageProfile: {
      osDisk: {
        name: os_disk_name
        caching: 'ReadWrite'
        createOption: 'FromImage'
        diskSizeGB: os_disk_size_gb
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'windows-11'
        sku: 'win11-22h2-pro'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
  tags: tags
}

output vm_id string = vm.id
output vm_private_ip string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output vm_public_ip string = publicIP.properties.ipAddress
