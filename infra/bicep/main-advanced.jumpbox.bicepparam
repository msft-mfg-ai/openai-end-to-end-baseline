// Example parameters file for deploying main-advanced.bicep with jumpbox VM
// Usage: az deployment group create --resource-group <your-rg> --template-file main-advanced.bicep --parameters @main-advanced.jumpbox.bicepparam

using './main-advanced.bicep'

// Basic deployment parameters
param applicationName = 'ai-chat-baseline'
param environmentName = 'dev'
param location = 'East US'
param yourPrincipalId = '<your-azure-ad-object-id>'

// OpenAI configuration
param openAI_deploy_location = 'East US'

// Network security
param myIpAddress = '<your-public-ip-address>'

// Jumpbox VM configuration (optional - remove or leave empty to skip VM deployment)
param admin_username = 'azureuser'
param admin_password = '<secure-password-min-12-chars>'
param vm_name = 'jumpbox-vm'

// Example Application Gateway certificate (if needed)
// param appGatewayListenerCertificate = '<base64-encoded-certificate-data>'

// Existing resources (optional)
// param existing_ACR_Name = ''
// param existing_ACR_ResourceGroupName = ''
