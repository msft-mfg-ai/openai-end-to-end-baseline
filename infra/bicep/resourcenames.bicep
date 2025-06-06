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
output appInsightsName string             = toLower('${resourceAbbreviations.insightsComponents}-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')
output logAnalyticsWorkspaceName string   = toLower('${resourceAbbreviations.operationalInsightsWorkspaces}-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')

output cosmosName string                  = toLower('${resourceAbbreviations.documentDBDatabaseAccounts}-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')

output apimName string                    = toLower('${resourceAbbreviations.apiManagementService}-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')

output searchServiceName string           = toLower('${resourceAbbreviations.searchSearchServices}-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')
output cogServiceName string              = toLower('${resourceAbbreviations.cognitiveServicesFoundry}-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')
output documentIntelligenceName string    = toLower('${resourceAbbreviations.documentIntelligence}-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')
output aiHubName string                   = toLower('${resourceAbbreviations.cognitiveServicesAIHub}-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')
// AI Hub Project name must be alpha numeric characters or '-', length must be <= 32
output aiHubProjectName string            = take(toLower('${resourceAbbreviations.cognitiveServicesHubProject}-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashInstance}'), 32)
output aiHubFoundryProjectName string     = take(toLower('${resourceAbbreviations.cognitiveServicesFoundryProject}-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashInstance}'), 32)

output caManagedEnvName string            = toLower('${resourceAbbreviations.appManagedEnvironments}-${sanitizedAppName}-${sanitizedEnvironment}${resourceToken}${dashRegionDashInstance}')
// CA name must be lower case alpha or '-', must start and end with alpha, cannot have '--', length must be <= 32
output containerAppAPIName string         = take(toLower('${resourceAbbreviations.appContainerApps}-api-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashInstance}'), 32)
output containerAppUIName string          = take(toLower('${resourceAbbreviations.appContainerApps}-ui-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashInstance}'), 32)
output containerAppBatchName string       = take(toLower('${resourceAbbreviations.appContainerApps}-batch-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashInstance}'), 32)

output caManagedIdentityName string       = toLower('${resourceAbbreviations.managedIdentityUserAssignedIdentities}-${sanitizedAppName}-${resourceAbbreviations.appManagedEnvironments}-${sanitizedEnvironment}${dashInstance}')
output kvManagedIdentityName string       = toLower('${resourceAbbreviations.managedIdentityUserAssignedIdentities}-${sanitizedAppName}-${resourceAbbreviations.keyVaultVaults}-${sanitizedEnvironment}${dashInstance}')
output userAssignedIdentityName string    = toLower('${resourceAbbreviations.managedIdentityUserAssignedIdentities}-${sanitizedAppName}-app-${sanitizedEnvironment}${dashInstance}')

output vnet_Name string                   = toLower('${sanitizedAppName}-${resourceAbbreviations.networkVirtualNetworks}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')
output vnetAppSubnetName string           = toLower('snet-app')
output vnetPeSubnetName string            = toLower('snet-prv-endpoint')

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
// Container Registry, Key Vaults and Storage Account names are only alpha numeric characters limited length
output ACR_Name string                    = take('${resourceAbbreviations.containerRegistryRegistries}${sanitizedAppName}${sanitizedEnvironment}${resourceTokenWithoutDash}${regionInstance}', 50)
output keyVaultName string                = take('${resourceAbbreviations.keyVaultVaults}${sanitizedAppName}${sanitizedEnvironment}${resourceTokenWithoutDash}${regionInstance}', 24)
output storageAccountName string          = take('${resourceAbbreviations.storageStorageAccounts}${sanitizedAppName}${sanitizedEnvironment}${resourceTokenWithoutDash}${regionInstance}', 24)
