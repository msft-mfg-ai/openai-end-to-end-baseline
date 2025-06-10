# Virtual Machine Module

This module deploys a virtual machine (VM) in Azure with configurable Windows or Linux operating systems, secure networking, and proper resource management.

## Features

- **Dual OS Support**: Configurable for Windows 11 or Ubuntu 20.04 LTS
- **Secure Networking**: Network Security Group with IP-restricted access
- **Flexible Configuration**: Configurable VM size, disk size, and network settings
- **Auto-naming**: Automatic naming of associated resources (NIC, Public IP, NSG, OS Disk)
- **Security Best Practices**: Restricted NSG rules, premium storage, automatic updates

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `vm_name` | string | (required) | Name of the Virtual Machine |
| `location` | string | resourceGroup().location | Location for all resources |
| `admin_username` | string | (required) | Admin username for the VM |
| `admin_password` | secureString | (required) | Admin password for the VM |
| `vnet_id` | string | (required) | Virtual Network resource ID |
| `subnet_name` | string | (required) | Subnet name within the Virtual Network |
| `vm_size` | string | Standard_D4s_v5 | VM size |
| `os_disk_size_gb` | int | 128 | OS disk size in GB |
| `os_type` | string | Windows | Operating system type: Windows or Linux |
| `my_ip_address` | string | '' | Your IP address for restricted NSG access |
| `tags` | object | {} | Tags to apply to resources |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `vm_id` | string | Virtual Machine resource ID |
| `vm_private_ip` | string | Private IP address of the VM |
| `vm_public_ip` | string | Public IP address of the VM |

## Usage Example

```bicep
module jumpboxVM './modules/virtualMachine/virtualMachine.bicep' = {
  name: 'jumpboxVirtualMachineDeployment'
  params: {
    vm_name: 'jumpbox-vm'
    admin_username: 'azureuser'
    admin_password: 'SecurePassword123!'
    vnet_id: vnet.outputs.vnetResourceId
    subnet_name: 'snet-jumpbox'
    os_type: 'Linux'
    vm_size: 'Standard_B2s_v2'
    my_ip_address: '203.0.113.1'
    location: location
    tags: tags
  }
}
```

## Network Security

The module creates a Network Security Group with:

### Windows VM Rules:
- **RDP (3389)**: Inbound access restricted to your IP address (if provided)
- **HTTPS (443)**: Outbound internet access
- **HTTP (80)**: Outbound internet access

### Linux VM Rules:
- **SSH (22)**: Inbound access restricted to your IP address (if provided)
- **HTTPS (443)**: Outbound internet access
- **HTTP (80)**: Outbound internet access

## OS Configurations

### Windows 11 Pro
- Publisher: MicrosoftWindowsDesktop
- Offer: windows-11
- SKU: win11-22h2-pro
- Automatic updates enabled
- Automatic patch mode

### Ubuntu 20.04 LTS
- Publisher: Canonical
- Offer: 0001-com-ubuntu-server-focal
- SKU: 20_04-lts-gen2
- Password authentication enabled
- Image default patch mode

## Storage

- OS Disk: Premium_LRS managed disk
- Default size: 128 GB (configurable)
- Caching: ReadWrite

## Security Considerations

1. **IP Restriction**: Provide `my_ip_address` parameter to restrict access to your IP only
2. **Secure Passwords**: Use strong passwords with minimum 12 characters
3. **Network Isolation**: VM is deployed in a private subnet
4. **Managed Disks**: Uses Premium SSD for better performance and security
5. **Automatic Updates**: Enabled for both Windows and Linux

## Integration with main-advanced.bicep

The VM module is conditionally deployed in main-advanced.bicep when VM parameters are provided:

```bicep
module virtualMachine './modules/virtualMachine/virtualMachine.bicep' = if (!empty(admin_username) && !empty(admin_password) && !empty(vm_name)) {
  name: 'jumpboxVirtualMachineDeployment'
  params: {
    admin_username: admin_username 
    admin_password: admin_password 
    vm_name: vm_name
    subnet_name: resourceNames.outputs.subnetJumpboxName
    vnet_id: vnet.outputs.vnetResourceId
    os_type: 'Linux'
    vm_size: 'Standard_B2s_v2'
    my_ip_address: myIpAddress
    location: location
    tags: tags
  }
}
```

To deploy with a jumpbox VM, provide the required parameters:
- `admin_username`
- `admin_password` 
- `vm_name`

If any of these are empty, the VM will not be deployed.
