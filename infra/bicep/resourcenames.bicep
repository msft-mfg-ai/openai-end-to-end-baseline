// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
// Bicep file that builds all the resource names used by other Bicep templates
// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
@description('Application name unique to this application, typically 5-8 characters.')
param applicationName string = ''

@description('Environment name for the application, e.g. azd, dev, demo, qa, stg, ct, prod. This is used to differentiate resources in different environments.')
param environmentName string = 'dev'

@description('Global Region where the resources will be deployed, e.g. AM (America), EM (EMEA), AP (APAC), CH (China)')
@allowed(['AM', 'EM', 'AP', 'CH'])
param regionCode string = 'AM'

@description('Instance number for the application, e.g. 001, 002, etc. This is used to differentiate multiple instances of the same application in the same environment.')
param instance string = ''

@description('Optional resource token to ensure uniqueness - leave blank if desired')
param resourceToken string = ''

//06/09/2025 parameters for vitualmachine jumpbox



// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
// Scrub inputs and create repeatable variables
// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
var sanitizedEnvironment = toLower(environmentName)
var sanitizedAppNameWithDashes = replace(replace(toLower(applicationName), ' ', ''), '_', '')
var sanitizedAppName = replace(replace(replace(toLower(applicationName), ' ', ''), '-', ''), '_', '')

var resourceTokenWithDash = resourceToken == '' ? '' : '-${resourceToken}'
var resourceTokenWithoutDash = resourceToken == '' ? '' : '${resourceToken}'

var dashRegionDashInstance = instance == '' ? '' : toLower('-${regionCode}-${instance}')
var dashInstance = instance == '' ? '' : '-${instance}'
var regionInstance = instance == '' ? '' : toLower('${regionCode}${instance}')

// pull resource abbreviations from a common JSON file
var resourceAbbreviations = loadJsonContent('./data/abbreviation.json')

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
output webSiteName string                 = toLower('${resourceAbbreviations.webSitesAppService}-${sanitizedAppNameWithDashes}-${sanitizedEnvironment}${resourceTokenWithDash}')
output webSiteAppServicePlanName string   = toLower('${resourceAbbreviations.webServerFarms}-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')
output appInsightsName string             = toLower('${resourceAbbreviations.insightsComponents}${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')
output logAnalyticsWorkspaceName string   = toLower('${resourceAbbreviations.operationalInsightsWorkspaces}${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')

output cosmosName string                  = toLower('${resourceAbbreviations.documentDBDatabaseAccounts}${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')

output searchServiceName string           = toLower('${resourceAbbreviations.searchSearchServices}${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')
output cogServiceName string              = toLower('${resourceAbbreviations.cognitiveServicesAccounts}${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')
output documentIntelligenceName string    = toLower('${resourceAbbreviations.cognitiveServicesFormRecognizer}${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')

output aiHubName string                   = toLower('${resourceAbbreviations.cognitiveServicesHub}-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')
// Project name must be alpha numeric characters or '-', length must be <= 32
output aiHubProjectName string            = take(toLower('${resourceAbbreviations.cognitiveServicesHub}-Project-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashInstance}'), 32)

output caManagedEnvName string            = toLower('${resourceAbbreviations.appManagedEnvironments}${sanitizedAppName}-${sanitizedEnvironment}${resourceToken}${dashRegionDashInstance}')
// CA name must be lower case alpha or '-', must start and end with alpha, cannot have '--', length must be <= 32
output containerAppAPIName string         = take(toLower('${resourceAbbreviations.appContainerApps}api-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashInstance}'), 32)
output containerAppUIName string          = take(toLower('${resourceAbbreviations.appContainerApps}ui-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashInstance}'), 32)
output containerAppBatchName string       = take(toLower('${resourceAbbreviations.appContainerApps}batch-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashInstance}'), 32)

output caManagedIdentityName string       = toLower('${sanitizedAppName}-${resourceAbbreviations.appManagedEnvironments}${resourceAbbreviations.managedIdentityUserAssignedIdentities}${dashInstance}-${sanitizedEnvironment}')
output kvManagedIdentityName string       = toLower('${sanitizedAppName}-${resourceAbbreviations.keyVaultVaults}${resourceAbbreviations.managedIdentityUserAssignedIdentities}${dashInstance}-${sanitizedEnvironment}')
output userAssignedIdentityName string    = toLower('${sanitizedAppName}-app-${resourceAbbreviations.managedIdentityUserAssignedIdentities}${dashInstance}-${sanitizedEnvironment}')

output vnet_Name string                   = toLower('${sanitizedAppName}-${resourceAbbreviations.networkVirtualNetworks}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')
//param vnetPrefix string = '10.183.4.0/22'
output subnetAppGwName string           = toLower('snet-app-gateway')
//param subnetAppGwPrefix string = '10.183.5.0/24'
output subnetAppSeName string            = toLower('snet-app-services')
//param subnetAppSePrefix string = '10.183.4.0/24'
output subnetPeName string           = toLower('snet-private-endpoint')
//param subnetPePrefix string = '10.183.6.0/27'
output subnetAgentName string           = toLower('snet-agent')
//param subnetAgentPrefix string = '10.183.6.32/27'
output subnetBastionName string       = 'AzureBastionSubnet' // Must be exactly this name for Azure Bastion
//param subnetBastionPrefix string = '10.183.6.64/26'
output subnetJumpboxName string       = toLower('snet-jumpbox')  
//param subnetJumpboxPrefix string = '10.183.6.128/28'
output subnetTrainingName string      = toLower('snet-training')
//param subnetTrainingPrefix string = '10.183.7.0/25'
output subnetScoringName string       = toLower('snet-scoring')
//param subnetScoringPrefix string = '10.183.7.128/25'


//06/09/2023 - Added Virtual Machine names by Fernando Ewald
output vm_name string                  = take(toLower('${sanitizedAppName}-${resourceAbbreviations.computeVirtualMachines}${dashInstance}-${sanitizedEnvironment}'),15)
output vm_nic_name string              = toLower('${sanitizedAppName}-${resourceAbbreviations.networkNetworkInterfaces}${dashInstance}-${sanitizedEnvironment}')  
output vm_pip_name string              = toLower('${sanitizedAppName}-${resourceAbbreviations.networkPublicIPAddresses}${dashInstance}-${sanitizedEnvironment}')
output vm_os_disk_name string          = toLower('${sanitizedAppName}-${resourceAbbreviations.computeDisks}${dashInstance}-${sanitizedEnvironment}')     
output vm_nsg_name string              = toLower('${sanitizedAppName}-${resourceAbbreviations.networkNetworkSecurityGroups}${dashInstance}-${sanitizedEnvironment}')
output bastion_host_name string        = toLower('${sanitizedAppName}-${resourceAbbreviations.networkBastionHosts}${dashInstance}-${sanitizedEnvironment}')
output bastion_pip_name string         = toLower('${sanitizedAppName}-${resourceAbbreviations.networkPublicIPAddresses}-bastion${dashInstance}-${sanitizedEnvironment}')

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
// Container Registry, Key Vaults and Storage Account names are only alpha numeric characters limited length
output ACR_Name string                    = take('${resourceAbbreviations.containerRegistryRegistries}${sanitizedAppName}${sanitizedEnvironment}${resourceTokenWithoutDash}${regionInstance}', 50)
output keyVaultName string                = take('${resourceAbbreviations.keyVaultVaults}${sanitizedAppName}${sanitizedEnvironment}${resourceTokenWithoutDash}${regionInstance}', 24)
output storageAccountName string          = take('${resourceAbbreviations.storageStorageAccounts}${sanitizedAppName}${sanitizedEnvironment}${resourceTokenWithoutDash}${regionInstance}', 24)
