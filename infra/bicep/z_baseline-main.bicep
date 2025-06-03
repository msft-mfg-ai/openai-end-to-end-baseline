// --------------------------------------------------------------------------------------------------------------
// Main bicep file that deploys EVERYTHING for the application, with optional parameters for existing resources.
// --------------------------------------------------------------------------------------------------------------
// You can test it with this commands:
//   az deployment group create -n manual --resource-group rg_mfg-ai-lz --template-file 'main.bicep' --parameters baseName='yourbasename' appGatewayListenerCertificate='yourcertdata' jumpBoxAdminPassword='yourPassword' yourPrincipalId='yourprincipalId'
// --------------------------------------------------------------------------------------------------------------

@description('The location in which all resources should be deployed.')
param location string = resourceGroup().location

@description('This is the base name for each Azure resource name (6-8 chars)')
@minLength(6)
@maxLength(14)
param baseName string

@description('Domain name to use for App Gateway')
param customDomainName string = 'contoso.com'

@description('The certificate data for app gateway TLS termination. The value is base64 encoded')
@secure()
param appGatewayListenerCertificate string

@description('The name of the web deploy file. The file should reside in a deploy container in the storage account. Defaults to chatui.zip')
param publishFileName string = 'chatui.zip'

@description('Specifies the password of the administrator account on the Windows jump box.\n\nComplexity requirements: 3 out of 4 conditions below need to be fulfilled:\n- Has lower characters\n- Has upper characters\n- Has a digit\n- Has a special character\n\nDisallowed values: "abc@123", "P@$$w0rd", "P@ssw0rd", "P@ssword123", "Pa$$word", "pass@word1", "Password!", "Password1", "Password22", "iloveyou!"')
@secure()
@minLength(8)
@maxLength(123)
param jumpBoxAdminPassword string

@description('Assign your user some roles to support fluid access when working in the Azure AI Foundry portal')
@maxLength(36)
param yourPrincipalId string

@description('Set to true to opt-out of deployment telemetry.')
param telemetryOptOut bool = true
@description('Set to true to deploy the web app and Application Gateway.')
param deployWebApp bool = false
@description('Set to true to deploy the jump box.')
param deployJumpBox bool = false

// --------------------------------------------------------------------------------------------------------------
// A variable masquerading as a parameter to allow for dynamic value assignment in Bicep
// --------------------------------------------------------------------------------------------------------------
param runDateTime string = utcNow()

// --------------------------------------------------------------------------------------------------------------
// -- Variables -------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
// var resourceToken = toLower(uniqueString(resourceGroup().id, location))
var resourceGroupName = resourceGroup().name

// --------------------------------------------------------------------------------------------------------------
// Customer Usage Attribution Id
var varCuaid = 'a52aa8a8-44a8-46e9-b7a5-189ab3a64409'
var deploymentSuffix = '-${runDateTime}'

// --------------------------------------------------------------------------------------------------------------
// ---- Log Analytics workspace ----
// --------------------------------------------------------------------------------------------------------------
resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-${baseName}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    forceCmkForQuery: false
    workspaceCapping: {
      dailyQuotaGb: 10 // Production readiness change: In production, tune this value to ensure operational logs are collected, but a reasonable cap is set.
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// --------------------------------------------------------------------------------------------------------------
// Deploy Virtual Network, with subnets, NSGs, and DDoS Protection.
// --------------------------------------------------------------------------------------------------------------
module networkModule './unused/original_root/network.bicep' = {
  name: 'networkDeploy${deploymentSuffix}'
  params: {
    location: location
    baseName: baseName
  }
}

@description('Deploys Azure Bastion and the jump box, which is used for private access to the Azure ML and Azure OpenAI portals.')
module jumpBoxModule './unused/original_root/jumpbox.bicep' = if (deployJumpBox) {
  name: 'jumpBoxDeploy${deploymentSuffix}'
  params: {
    location: location
    baseName: baseName
    virtualNetworkName: networkModule.outputs.vnetNName
    logWorkspaceName: logWorkspace.name
    jumpBoxAdminName: 'vmadmin'
    jumpBoxAdminPassword: jumpBoxAdminPassword
  }
}

// --------------------------------------------------------------------------------------------------------------
// Deploy Azure Storage account with private endpoint and private DNS zone
// --------------------------------------------------------------------------------------------------------------
module storageModule './unused/original_root/storage.bicep' = {
  name: 'storageDeploy${deploymentSuffix}'
  params: {
    location: location
    baseName: baseName
    vnetName: networkModule.outputs.vnetNName
    privateEndpointsSubnetName: networkModule.outputs.privateEndpointsSubnetName
    logWorkspaceName: logWorkspace.name
    yourPrincipalId: yourPrincipalId
  }
}

// --------------------------------------------------------------------------------------------------------------
// Deploy Azure Key Vault with private endpoint and private DNS zone
// --------------------------------------------------------------------------------------------------------------
module keyVaultModule './unused/original_root/keyvault.bicep' = {
  name: 'keyVaultDeploy${deploymentSuffix}'
  params: {
    location: location
    baseName: baseName
    vnetName: networkModule.outputs.vnetNName
    privateEndpointsSubnetName: networkModule.outputs.privateEndpointsSubnetName
    appGatewayListenerCertificate: appGatewayListenerCertificate
    logWorkspaceName: logWorkspace.name
  }
}

// --------------------------------------------------------------------------------------------------------------
// Deploy Azure Container Registry with private endpoint and private DNS zone
// --------------------------------------------------------------------------------------------------------------
module acrModule './unused/original_root/acr.bicep' = {
  name: 'acrDeploy${deploymentSuffix}'
  params: {
    location: location
    baseName: baseName
    vnetName: networkModule.outputs.vnetNName
    privateEndpointsSubnetName: networkModule.outputs.privateEndpointsSubnetName
    buildAgentSubnetName: networkModule.outputs.agentSubnetName
    logWorkspaceName: logWorkspace.name
  }
}

// --------------------------------------------------------------------------------------------------------------
// Deploy Application Insights and Log Analytics workspace
// --------------------------------------------------------------------------------------------------------------
module appInsightsModule './unused/original_root/applicationinsights.bicep' = {
  name: 'appInsightsDeploy${deploymentSuffix}'
  params: {
    location: location
    baseName: baseName
    logWorkspaceName: logWorkspace.name
  }
}

// --------------------------------------------------------------------------------------------------------------
// Deploy Azure OpenAI service with private endpoint and private DNS zone
// --------------------------------------------------------------------------------------------------------------
module openaiModule './unused/original_root/openai.bicep' = {
  name: 'openaiDeploy${deploymentSuffix}'
  params: {
    location: location
    baseName: baseName
    vnetName: networkModule.outputs.vnetNName
    privateEndpointsSubnetName: networkModule.outputs.privateEndpointsSubnetName
    logWorkspaceName: logWorkspace.name
  }
}

// --------------------------------------------------------------------------------------------------------------
// Deploy Azure AI Foundry with private networking
// --------------------------------------------------------------------------------------------------------------
module aiStudioModule './unused/original_root/machinelearning.bicep' = {
  name: 'aiStudioDeploy${deploymentSuffix}'
  params: {
    location: location
    baseName: baseName
    vnetName: networkModule.outputs.vnetNName
    privateEndpointsSubnetName: networkModule.outputs.privateEndpointsSubnetName
    applicationInsightsName: appInsightsModule.outputs.applicationInsightsName
    keyVaultName: keyVaultModule.outputs.keyVaultName
    aiStudioStorageAccountName: storageModule.outputs.mlDeployStorageName
    containerRegistryName: 'cr${baseName}'
    logWorkspaceName: logWorkspace.name
    openAiResourceName: openaiModule.outputs.openAiResourceName
    yourPrincipalId: yourPrincipalId
  }
}

// --------------------------------------------------------------------------------------------------------------
//Deploy an Azure Application Gateway with WAF v2 and a custom domain name.
// --------------------------------------------------------------------------------------------------------------
module gatewayModule './unused/original_root/gateway.bicep' = if (deployWebApp) {
  name: 'gatewayDeploy${deploymentSuffix}'
  params: {
    location: location
    baseName: baseName
    customDomainName: customDomainName
    appName: webappModule.outputs.appName
    vnetName: networkModule.outputs.vnetNName
    appGatewaySubnetName: networkModule.outputs.appGatewaySubnetName
    keyVaultName: keyVaultModule.outputs.keyVaultName
    gatewayCertSecretKey: keyVaultModule.outputs.gatewayCertSecretKey
    logWorkspaceName: logWorkspace.name
  }
}

// --------------------------------------------------------------------------------------------------------------
// Deploy the web apps for the front end demo UI and the containerised promptflow endpoint
// --------------------------------------------------------------------------------------------------------------
module webappModule './unused/original_root/webapp.bicep' = if (deployWebApp) {
  name: 'webappDeploy${deploymentSuffix}'
  params: {
    location: location
    baseName: baseName
    managedOnlineEndpointResourceId: aiStudioModule.outputs.managedOnlineEndpointResourceId
    acrName: acrModule.outputs.acrName
    publishFileName: publishFileName
    openAIName: openaiModule.outputs.openAiResourceName
    keyVaultName: keyVaultModule.outputs.keyVaultName
    storageName: storageModule.outputs.appDeployStorageName
    vnetName: networkModule.outputs.vnetNName
    appServicesSubnetName: networkModule.outputs.appServicesSubnetName
    privateEndpointsSubnetName: networkModule.outputs.privateEndpointsSubnetName
    logWorkspaceName: logWorkspace.name
  }
}
