// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
// Bicep file that builds all the resource names used by other Bicep templates
// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
@description('Application name unique to this application, typically 5-8 characters.')
param applicationName string = ''

@description('Environment name for the application, e.g. azd, dev, demo, qa, stg, ct, prod. This is used to differentiate resources in different environments.')
param environmentName string = 'dev'

@description('Global Region where the resources will be deployed, e.g. AM (America), EM (EMEA), AP (APAC), CH (China)')
//@allowed(['AM', 'EM', 'AP', 'CH', 'NAA'])
param regionCode string = 'NAA'

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
output aiHubProjectName string            = take(toLower('${resourceAbbreviations.cognitiveServicesHubProject}-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}'), 32)
output aiHubFoundryProjectName string     = take(toLower('${resourceAbbreviations.cognitiveServicesFoundryProject}-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}'), 32)

output caManagedEnvName string            = toLower('${resourceAbbreviations.appManagedEnvironments}-${sanitizedAppName}-${sanitizedEnvironment}${resourceToken}${dashRegionDashInstance}')
// CA name must be lower case alpha or '-', must start and end with alpha, cannot have '--', length must be <= 32
output containerAppAPIName string         = take(toLower('${resourceAbbreviations.appContainerApps}-api-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}'), 32)
output containerAppUIName string          = take(toLower('${resourceAbbreviations.appContainerApps}-ui-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}'), 32)
output containerAppBatchName string       = take(toLower('${resourceAbbreviations.appContainerApps}-bat-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}'), 32)

output caManagedIdentityName string       = toLower('${resourceAbbreviations.managedIdentityUserAssignedIdentities}-${sanitizedAppName}-${resourceAbbreviations.appManagedEnvironments}-${sanitizedEnvironment}${dashRegionDashInstance}')
output kvManagedIdentityName string       = toLower('${resourceAbbreviations.managedIdentityUserAssignedIdentities}-${sanitizedAppName}-${resourceAbbreviations.keyVaultVaults}-${sanitizedEnvironment}${dashRegionDashInstance}')
output userAssignedIdentityName string    = toLower('${resourceAbbreviations.managedIdentityUserAssignedIdentities}-${sanitizedAppName}-${sanitizedEnvironment}${dashRegionDashInstance}')

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
// Container Registry, Key Vaults and Storage Account names are only alpha numeric characters limited length
output ACR_Name string                    = take('${resourceAbbreviations.containerRegistryRegistries}${sanitizedAppName}${sanitizedEnvironment}${resourceTokenWithoutDash}${regionInstance}', 50)
output keyVaultName string                = take('${resourceAbbreviations.keyVaultVaults}${sanitizedAppName}${sanitizedEnvironment}${resourceTokenWithoutDash}${regionInstance}', 24)
output storageAccountName string          = take('${resourceAbbreviations.storageStorageAccounts}${sanitizedAppName}${sanitizedEnvironment}${resourceTokenWithoutDash}${regionInstance}', 24)

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
// Network resource names
// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
output vnet_Name string                   = toLower('${sanitizedAppName}-${resourceAbbreviations.networkVirtualNetworks}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')
output subnetAppGwName string             = toLower('snet-app-gateway')
output subnetAppSeName string             = toLower('snet-app-services')
output subnetPeName string                = toLower('snet-private-endpoint')
output subnetAgentName string             = toLower('snet-agent')
output subnetBastionName string           = 'AzureBastionSubnet' // Must be exactly this name for Azure Bastion
output subnetJumpboxName string           = toLower('snet-jumpbox')  
output subnetTrainingName string          = toLower('snet-training')
output subnetScoringName string           = toLower('snet-scoring')

output vm_name string                     = take(toLower('${resourceAbbreviations.computeVirtualMachines}-${sanitizedAppName}${dashInstance}-${sanitizedEnvironment}'),14)
output vm_nic_name string                 = toLower('${resourceAbbreviations.networkNetworkInterfaces}${sanitizedAppName}${dashInstance}-${sanitizedEnvironment}')
output vm_pip_name string                 = toLower('${resourceAbbreviations.networkPublicIPAddresses}${sanitizedAppName}${dashInstance}-${sanitizedEnvironment}')
output vm_os_disk_name string             = toLower('${resourceAbbreviations.computeDisks}${sanitizedAppName}${dashInstance}-${sanitizedEnvironment}')
output vm_nsg_name string                 = toLower('${resourceAbbreviations.networkNetworkSecurityGroups}${sanitizedAppName}${dashInstance}${sanitizedEnvironment}')
output bastion_host_name string           = toLower('${resourceAbbreviations.networkBastionHosts}${sanitizedAppName}${dashInstance}-${sanitizedEnvironment}')
output bastion_pip_name string         =    toLower('${resourceAbbreviations.networkPublicIPAddresses}${sanitizedAppName}${resourceAbbreviations.bastionPip}${dashInstance}-${sanitizedEnvironment}')

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
// Private Endpoint Names (sequential) -- created for the customer need
output peStorageAccountBlobName string = 'pep-${sanitizedAppName}-${sanitizedEnvironment}-${regionCode}-001'
output peStorageAccountTableName string = 'pep-${sanitizedAppName}-${sanitizedEnvironment}-${regionCode}-002'
output peStorageAccountQueueName string = 'pep-${sanitizedAppName}-${sanitizedEnvironment}-${regionCode}-003'
output peCosmosDbName string = 'pep-${sanitizedAppName}-${sanitizedEnvironment}-${regionCode}-004'
output peKeyVaultName string = 'pep-${sanitizedAppName}-${sanitizedEnvironment}-${regionCode}-005'
output peAcrName string = 'pep-${sanitizedAppName}-${sanitizedEnvironment}-${regionCode}-006'
output peSearchServiceName string = 'pep-${sanitizedAppName}-${sanitizedEnvironment}-${regionCode}-007'
output peOpenAIName string = 'pep-${sanitizedAppName}-${sanitizedEnvironment}-${regionCode}-008'
output peContainerAppsName string = 'pep-${sanitizedAppName}-${sanitizedEnvironment}-${regionCode}-009'

output peDocumentIntelligenceName string = 'pep-${sanitizedAppName}-${sanitizedEnvironment}-${regionCode}-010'
output peOpenAIServiceConnection string = 'pep-${sanitizedAppName}-${sanitizedEnvironment}-${regionCode}-011'
output peAIHubName string = 'pep-${sanitizedAppName}-${sanitizedEnvironment}-${regionCode}-012'
output peAppInsightsName string = 'pep-${sanitizedAppName}-${sanitizedEnvironment}-${regionCode}-013'
output peMonitorName string = 'pep-${sanitizedAppName}-${sanitizedEnvironment}-${regionCode}-014'

output vnetNsgName string = '${resourceAbbreviations.networkNetworkSecurityGroups}${sanitizedAppName}-${sanitizedEnvironment}-${regionCode}-001'

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
// Application Gateway resource names
// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
output appGatewayName string = toLower('${resourceAbbreviations.networkApplicationGateways}${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')
output appGatewayWafPolicyName string = toLower('${resourceAbbreviations.networkFirewallPoliciesWebApplication}-${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')
output appGatewayPublicIpName string = toLower('${resourceAbbreviations.networkPublicIPAddresses}${sanitizedAppName}-agw-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')

// Monitoring and Alerting resource names
output actionGroupName string             = toLower('${resourceAbbreviations.insightsActionGroups}${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')
output smartDetectorAlertRuleName string  = toLower('${resourceAbbreviations.insightsSmartDetectorAlertRules}${sanitizedAppName}-${sanitizedEnvironment}${resourceTokenWithDash}${dashRegionDashInstance}')
