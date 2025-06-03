// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
// Bicep file that builds all the resource names used by other Bicep templates
// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
param applicationName string = ''

// @allowed(['azd','dev','demo','qa','stg','ct','prod'])
param environmentName string = 'dev'

@description('Azure region where the resources will be deployed, e.g. eastus, westus, etc.')
param region string = ''
@description('Instance number for the application, e.g. 001, 002, etc. This is used to differentiate multiple instances of the same application in the same environment.')
param instance string = ''

@description('Optional resource token to ensure uniqueness - leave blank if desired')
param resourceToken string = ''

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
var sanitizedEnvironment = toLower(environmentName)
var sanitizedAppNameWithDashes = replace(replace(toLower(applicationName), ' ', ''), '_', '')
var sanitizedAppName = replace(replace(replace(toLower(applicationName), ' ', ''), '-', ''), '_', '')

var resourceTokenWithDash = resourceToken == '' ? '' : '-${resourceToken}'
var resourceTokenWithoutDash = resourceToken == '' ? '' : '${resourceToken}'

var dashRegionDashInstance = instance == '' ? '' : '-${region}-${instance}'
var regionInstance = instance == '' ? '' : '${region}${instance}'

// pull resource abbreviations from a common JSON file
var resourceAbbreviations = loadJsonContent('./data/abbreviation.json')

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
output webSiteName string                 = toLower('${sanitizedAppNameWithDashes}-${sanitizedEnvironment}${resourceTokenWithDash}')

// plan-applicationname-environmentname-otisregion-instance
output webSiteAppServicePlanName string   = toLower('${resourceAbbreviations.webServerFarms}-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')

// appi-applicationname-environmentname-otisregion-instance
output appInsightsName string             = toLower('${sanitizedAppName}-${resourceAbbreviations.insightsComponents}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')

output logAnalyticsWorkspaceName string   = toLower('${sanitizedAppName}-${resourceAbbreviations.operationalInsightsWorkspaces}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')

output cosmosName string                  = toLower('${sanitizedAppName}-${resourceAbbreviations.documentDBDatabaseAccounts}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')

output searchServiceName string           = toLower('${sanitizedAppName}-${resourceAbbreviations.searchSearchServices}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')
output cogServiceName string              = toLower('${sanitizedAppName}-${resourceAbbreviations.cognitiveServicesAccounts}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')
output documentIntelligenceServiceName string = toLower('${sanitizedAppName}-${resourceAbbreviations.cognitiveServicesFormRecognizer}${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')

output aiHubName string                   = toLower('${sanitizedAppName}-${resourceAbbreviations.cognitiveServicesHub}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')
output aiHubProjectName string            = toLower('${sanitizedAppName}-${resourceAbbreviations.cognitiveServicesHub}-Project-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')

output caManagedEnvName string            = toLower('${sanitizedAppName}-${resourceAbbreviations.appManagedEnvironments}-${sanitizedEnvironment}${resourceToken}${dashRegionDashInstance}')
// CA name must be lower case alpha or '-', must start and end with alpha, cannot have '--', length must be <= 32
output containerAppAPIName string         = take(toLower('${sanitizedAppName}-${resourceAbbreviations.appContainerApps}-api-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}'), 32)
output containerAppUIName string          = take(toLower('${sanitizedAppName}-${resourceAbbreviations.appContainerApps}-ui-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}'), 32)
output containerAppBatchName string       = take(toLower('${sanitizedAppName}-${resourceAbbreviations.appContainerApps}-batch-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}'), 32)

output caManagedIdentityName string       = toLower('${sanitizedAppName}-${resourceAbbreviations.appManagedEnvironments}-${resourceAbbreviations.managedIdentityUserAssignedIdentities}-${sanitizedEnvironment}${resourceToken}${dashRegionDashInstance}')
output kvManagedIdentityName string       = toLower('${sanitizedAppName}-${resourceAbbreviations.keyVaultVaults}-${resourceAbbreviations.managedIdentityUserAssignedIdentities}-${sanitizedEnvironment}${resourceToken}${dashRegionDashInstance}')
output userAssignedIdentityName string    = toLower('${sanitizedAppName}-app-${resourceAbbreviations.managedIdentityUserAssignedIdentities}')

output vnet_Name string                   = toLower('${sanitizedAppName}-${resourceAbbreviations.networkVirtualNetworks}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')
output vnetAppSubnetName string           = toLower('snet-app')
output vnetPeSubnetName string            = toLower('snet-prv-endpoint')

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
// Container Registry, Key Vaults and Storage Account names are only alpha numeric characters limited length
output ACR_Name string                    = take('${sanitizedAppName}${resourceAbbreviations.containerRegistryRegistries}${sanitizedEnvironment}${resourceTokenWithoutDash}${regionInstance}', 50)
output keyVaultName string                = take('${sanitizedAppName}${resourceAbbreviations.keyVaultVaults}${sanitizedEnvironment}${resourceTokenWithoutDash}${regionInstance}', 24)
output storageAccountName string          = take('${sanitizedAppName}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${resourceTokenWithoutDash}${regionInstance}', 24)
