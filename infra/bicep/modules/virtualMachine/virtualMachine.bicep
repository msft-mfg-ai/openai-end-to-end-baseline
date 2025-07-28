@description('Name of the Virtual Machine')
param vm_name string

@description('Name of the Virtual Machine Physical Host')
param vm_computer_name string = vm_name

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

@description('Operating system type: Windows or Linux')
@allowed(['Windows', 'Linux'])
param os_type string = 'Windows'

@description('My IP address for restricted NSG access')
param my_ip_address string = ''

@description('Tags to apply to resources')
param tags object
//param tags string


param vm_nic_name string
param vm_pip_name string
param vm_os_disk_name string
param vm_nsg_name string



///home/runner/work/openai-end-to-end-baseline/openai-end-to-end-baseline/infra/bicep/main-advanced.bicep(315,3) : Error BCP035: The specified "object" 
//declaration is missing the following required properties: "vm_nic_name", "vm_nsg_name", "vm_os_disk_name", "vm_pip_name". 

var nic_name = vm_nic_name
var pip_name = vm_pip_name
var os_disk_name = vm_os_disk_name
var nsg_name = vm_nsg_name

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
    securityRules: concat(
      // SSH/RDP rules based on OS type and IP restriction
      os_type == 'Linux' ? [
        {
          name: 'SSH'
          properties: {
            priority: 1000
            direction: 'Inbound'
            access: 'Allow'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '22'
            sourceAddressPrefix: !empty(my_ip_address) ? my_ip_address : '*'
            destinationAddressPrefix: '*'
          }
        }
      ] : [
        {
          name: 'RDP'
          properties: {
            priority: 1000
            direction: 'Inbound'
            access: 'Allow'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '3389'
            sourceAddressPrefix: !empty(my_ip_address) ? my_ip_address : '*'
            destinationAddressPrefix: '*'
          }
        }
      ],
      // Common outbound rules
      [
        {
          name: 'AllowHttpsOutbound'
          properties: {
            priority: 2000
            direction: 'Outbound'
            access: 'Allow'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '443'
            sourceAddressPrefix: '*'
            destinationAddressPrefix: 'Internet'
          }
        }
        {
          name: 'AllowHttpOutbound'
          properties: {
            priority: 2010
            direction: 'Outbound'
            access: 'Allow'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '80'
            sourceAddressPrefix: '*'
            destinationAddressPrefix: 'Internet'
          }
        }
      ]
    )
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
      computerName: vm_computer_name
      adminUsername: admin_username
      adminPassword: admin_password
      windowsConfiguration: os_type == 'Windows' ? {
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
        }
      } : null
      linuxConfiguration: os_type == 'Linux' ? {
        disablePasswordAuthentication: false
        patchSettings: {
          patchMode: 'ImageDefault'
        }
      } : null
    }
    storageProfile: {
      osDisk: {
        name: os_disk_name
        caching: 'ReadWrite'
        createOption: 'FromImage'
        diskSizeGB: os_disk_size_gb
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: os_type == 'Windows' ? {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'windows-11'
        sku: 'win11-24h2-ent'
        version: 'latest'
      } : {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
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
