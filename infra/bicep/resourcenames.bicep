// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
// Bicep file that builds all the resource names used by other Bicep templates
// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
@description('Application name unique to this application, typically 5-8 characters.')
param applicationName string = ''

@description('Root Application Name that this is based on')
param rootApplication string = ''

@description('Environment name for the application, e.g. azd, dev, demo, qa, stg, ct, prod. This is used to differentiate resources in different environments.')
param environmentName string = 'dev'

@description('Global Region where the resources will be deployed, e.g. AM (America), EM (EMEA), AP (APAC), CH (China)')
//@allowed(['AM', 'EM', 'AP', 'CH', 'NAA'])
param regionCode string = 'NAA'

@description('Instance number for the application, e.g. 001, 002, etc. This is used to differentiate multiple instances of the same application in the same environment.')
@maxLength(3)
@minLength(3)
param instance string = '000'

@description('Optional resource token to ensure uniqueness - leave blank if desired')
param resourceToken string = ''

@description('Number of projects to create, used for AI Hub projects')
@minValue(1)
param numberOfProjects int = projectNumber+1

@description('Project number to use for AI Hub project names, must be less than or equal to numberOfProjects')
@minValue(1)
param projectNumber int=1

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
// Scrub inputs and create repeatable variables
// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
var sanitizedEnvironment = toLower(environmentName)
var environmentInitial = take(sanitizedEnvironment, 1)
var sanitizedAppNameWithDashes = replace(replace(toLower(applicationName), ' ', ''), '_', '')
var sanitizedAppName = replace(replace(replace(toLower(applicationName), ' ', ''), '-', ''), '_', '')
var sanitizedRootApplication = replace(replace(replace(toLower(rootApplication), ' ', ''), '-', ''), '_', '')

var resourceTokenWithDash = resourceToken == '' ? '' : '-${resourceToken}'
var resourceTokenWithoutDash = resourceToken == '' ? '' : '${resourceToken}'

var dashRegionDashInstance = instance == '' ? '' : toLower('-${regionCode}-${instance}')
var dashRegionDashProject = instance == '' ? '' : toLower('-${regionCode}-${projectNumber}')
var regionInstance = instance == '' ? '' : toLower('${regionCode}${instance}')
var partialInstance = substring(instance, 2, 1) // get last digit of a three digit code
var partialRegion = substring(regionCode, 0, 1) // get first digit of a two digit code

// pull resource abbreviations from a common JSON file
var resourceAbbreviations = loadJsonContent('./data/abbreviation.json')

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
output webSiteName string                 = toLower('${resourceAbbreviations.webSitesAppService}-${sanitizedAppNameWithDashes}-${environmentInitial}${resourceTokenWithDash}')
output webSiteAppServicePlanName string   = toLower('${resourceAbbreviations.webServerFarms}-${sanitizedAppName}-${environmentInitial}${resourceTokenWithDash}${dashRegionDashInstance}')
output appInsightsName string             = toLower('${resourceAbbreviations.insightsComponents}-${sanitizedAppName}-${environmentInitial}${resourceTokenWithDash}${dashRegionDashInstance}')
output logAnalyticsWorkspaceName string   = toLower('${resourceAbbreviations.operationalInsightsWorkspaces}-${sanitizedAppName}-${environmentInitial}${resourceTokenWithDash}${dashRegionDashInstance}')

output cosmosName string                  = toLower('${resourceAbbreviations.documentDBDatabaseAccounts}-${sanitizedAppName}-${environmentInitial}${resourceTokenWithDash}${dashRegionDashInstance}')

output apimName string                    = toLower('${resourceAbbreviations.apiManagementService}-${sanitizedAppName}-${environmentInitial}${resourceTokenWithDash}${dashRegionDashInstance}')

output searchServiceName string           = toLower('${resourceAbbreviations.searchSearchServices}-${sanitizedAppName}-${environmentInitial}${resourceTokenWithDash}${dashRegionDashInstance}')
output cogServiceName string              = toLower('${resourceAbbreviations.cognitiveServicesFoundry}-${sanitizedAppName}-${environmentInitial}${resourceTokenWithDash}${dashRegionDashInstance}')
output documentIntelligenceName string    = toLower('${resourceAbbreviations.documentIntelligence}-${sanitizedAppName}-${environmentInitial}${resourceTokenWithDash}${dashRegionDashInstance}')
output rootCogServiceName string          = toLower('${resourceAbbreviations.cognitiveServicesFoundry}-${sanitizedRootApplication}-${environmentInitial}${resourceTokenWithDash}${dashRegionDashInstance}')

output aiHubName string                   = toLower('${resourceAbbreviations.cognitiveServicesAIHub}-${sanitizedAppName}-${environmentInitial}${resourceTokenWithDash}${dashRegionDashInstance}')
// AI Hub Project name must be alpha numeric characters or '-', length must be <= 32
func getProjectName(no int) string => take(toLower('${resourceAbbreviations.cognitiveServicesFoundryProject}-${sanitizedAppName}-${no}-${environmentInitial}${resourceTokenWithDash}${dashRegionDashInstance}'), 32)
var aiProjectNames = [for i in range(1, numberOfProjects + 1): getProjectName(i)]

output aiHubProjectNames array = aiProjectNames
output aiHubProjectName string            = getProjectName(projectNumber) // Use the first project name as the AI Hub Project name

output aiHubFoundryProjectName string     = take(toLower('${resourceAbbreviations.cognitiveServicesFoundryProject}-${sanitizedAppName}-${environmentInitial}${resourceTokenWithDash}${dashRegionDashInstance}'), 32)

output caManagedEnvName string            = toLower('${resourceAbbreviations.appManagedEnvironments}-${sanitizedAppName}-${environmentInitial}${resourceToken}${dashRegionDashInstance}')
// CA name must be lower case alpha or '-', must start and end with alpha, cannot have '--', length must be <= 32
output containerAppAPIName string         = take(toLower('${resourceAbbreviations.appContainerApps}-api-${sanitizedAppName}-${environmentInitial}${resourceTokenWithDash}${dashRegionDashInstance}'), 32)
output containerAppUIName string          = take(toLower('${resourceAbbreviations.appContainerApps}-ui-${sanitizedAppName}-${environmentInitial}${resourceTokenWithDash}${dashRegionDashInstance}'), 32)
output containerAppBatchName string       = take(toLower('${resourceAbbreviations.appContainerApps}-bat-${sanitizedAppName}-${environmentInitial}${resourceTokenWithDash}${dashRegionDashInstance}'), 32)

output caManagedIdentityName string       = toLower('${resourceAbbreviations.managedIdentityUserAssignedIdentities}-${sanitizedAppName}-${resourceAbbreviations.appManagedEnvironments}-${environmentInitial}${dashRegionDashInstance}')
output kvManagedIdentityName string       = toLower('${resourceAbbreviations.managedIdentityUserAssignedIdentities}-${sanitizedAppName}-${resourceAbbreviations.keyVaultVaults}-${environmentInitial}${dashRegionDashInstance}')
output userAssignedIdentityName string    = toLower('${resourceAbbreviations.managedIdentityUserAssignedIdentities}-${sanitizedAppName}-${environmentInitial}${dashRegionDashInstance}')
output rootUserAssignedIdentityName string = toLower('${resourceAbbreviations.managedIdentityUserAssignedIdentities}-${sanitizedRootApplication}-${environmentInitial}${dashRegionDashInstance}')

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
// Container Registry, Key Vaults and Storage Account names are only alpha numeric characters limited length
output ACR_Name string                    = take('${resourceAbbreviations.containerRegistryRegistries}${sanitizedAppName}${environmentInitial}${resourceTokenWithoutDash}${regionInstance}', 50)
output keyVaultName string                = take('${resourceAbbreviations.keyVaultVaults}${sanitizedAppName}${environmentInitial}${resourceTokenWithoutDash}${regionInstance}', 24)
output storageAccountName string          = take('${resourceAbbreviations.storageStorageAccounts}${sanitizedAppName}${environmentInitial}${resourceTokenWithoutDash}${regionInstance}', 24)

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
// Network resource names
// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
output vnet_Name string                   = toLower('${resourceAbbreviations.networkVirtualNetworks}-${sanitizedAppName}-${environmentInitial}${dashRegionDashInstance}')
output root_vnet_Name string              = toLower('${resourceAbbreviations.networkVirtualNetworks}-${sanitizedRootApplication}-${environmentInitial}${dashRegionDashInstance}')
                               
output subnetAppGwName string             = toLower('snet-app-gateway')
output subnetAppSeName string             = toLower('snet-app-services')
output subnetPeName string                = toLower('snet-private-endpoint')
output subnetAgentName string             = toLower('snet-agent')
output subnetBastionName string           = 'AzureBastionSubnet' // Must be exactly this name for Azure Bastion
output subnetJumpboxName string           = toLower('snet-jumpbox')  
output subnetTrainingName string          = toLower('snet-training')
output subnetScoringName string           = toLower('snet-scoring')

// example:    vmoazaihubdam01
// new format: vmoaz<appname><regioncode><instance>
// appname:    otaihub
// resource 1: vmoazotaihubdam01
// computer 1: vmoazotaihubda1  (first 15 characters)
// resource 2: vmoazotaihubdam02
// computer 2: vmoazotaihubda2  (first 15 characters)
output vm_name string           = toLower('${resourceAbbreviations.computeVirtualMachines}oaz${sanitizedAppName}${environmentInitial}${regionCode}${instance}')
output vm_name_15 string        = take(toLower('${resourceAbbreviations.computeVirtualMachines}oaz${sanitizedAppName}${environmentInitial}${partialRegion}${partialInstance}'),15)
                                                    
output vm_nic_name string       = toLower('${resourceAbbreviations.networkNetworkInterfaces}${sanitizedAppName}-${environmentInitial}${dashRegionDashInstance}')
output vm_pip_name string       = toLower('${resourceAbbreviations.networkPublicIPAddresses}${sanitizedAppName}-${environmentInitial}${dashRegionDashInstance}')
output vm_os_disk_name string   = toLower('${resourceAbbreviations.computeDisks}-${sanitizedAppName}-${environmentInitial}${dashRegionDashInstance}')
output vm_nsg_name string       = toLower('${resourceAbbreviations.networkNetworkSecurityGroups}-${sanitizedAppName}-${environmentInitial}${dashRegionDashInstance}')
output bastion_host_name string = toLower('${resourceAbbreviations.networkBastionHosts}${sanitizedAppName}-${environmentInitial}${dashRegionDashInstance}')
output bastion_pip_name string  = toLower('${resourceAbbreviations.networkPublicIPAddresses}${sanitizedAppName}-${resourceAbbreviations.bastionPip}-${environmentInitial}${dashRegionDashInstance}')

output project_vm object = {
  vm_name:                        toLower('${resourceAbbreviations.computeVirtualMachines}oaz${sanitizedAppName}${environmentInitial}${regionCode}${projectNumber}')
  vm_name_15:                     take(toLower('${resourceAbbreviations.computeVirtualMachines}oaz${sanitizedAppName}${environmentInitial}${regionCode}${projectNumber}'),15)
  vm_nic_name:                    toLower('${resourceAbbreviations.networkNetworkInterfaces}${sanitizedAppName}-${environmentInitial}${dashRegionDashProject}')
  vm_pip_name:                    toLower('${resourceAbbreviations.networkPublicIPAddresses}${sanitizedAppName}-${environmentInitial}${dashRegionDashProject}')
  vm_os_disk_name:                toLower('${resourceAbbreviations.computeDisks}-${sanitizedAppName}-${environmentInitial}${dashRegionDashProject}')
  vm_nsg_name:                    toLower('${resourceAbbreviations.networkNetworkSecurityGroups}-${sanitizedAppName}-${environmentInitial}${dashRegionDashProject}')
  bastion_host_name:              toLower('${resourceAbbreviations.networkBastionHosts}${sanitizedAppName}-${environmentInitial}${dashRegionDashProject}')
  bastion_pip_name:               toLower('${resourceAbbreviations.networkPublicIPAddresses}${sanitizedAppName}-${resourceAbbreviations.bastionPip}-${environmentInitial}${dashRegionDashProject}')
}

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
// Private Endpoint Names (sequential) -- created for the customer need
output peStorageAccountBlobName string = toLower('pep-${sanitizedAppName}-${environmentInitial}-${regionCode}-001')
output peStorageAccountTableName string = toLower('pep-${sanitizedAppName}-${environmentInitial}-${regionCode}-002')
output peStorageAccountQueueName string = toLower('pep-${sanitizedAppName}-${environmentInitial}-${regionCode}-003')
output peCosmosDbName string = toLower('pep-${sanitizedAppName}-${environmentInitial}-${regionCode}-004')
output peKeyVaultName string = toLower('pep-${sanitizedAppName}-${environmentInitial}-${regionCode}-005')
output peAcrName string = toLower('pep-${sanitizedAppName}-${environmentInitial}-${regionCode}-006')
output peSearchServiceName string = toLower('pep-${sanitizedAppName}-${environmentInitial}-${regionCode}-007')
output peOpenAIName string = toLower('pep-${sanitizedAppName}-${environmentInitial}-${regionCode}-008')
output peContainerAppsName string = toLower('pep-${sanitizedAppName}-${environmentInitial}-${regionCode}-009')

output peDocumentIntelligenceName string = toLower('pep-${sanitizedAppName}-${environmentInitial}-${regionCode}-010')
output peOpenAIServiceConnection string = toLower('pep-${sanitizedAppName}-${environmentInitial}-${regionCode}-011')
output peAIHubName string = toLower('pep-${sanitizedAppName}-${environmentInitial}-${regionCode}-012')
output peAppInsightsName string = toLower('pep-${sanitizedAppName}-${environmentInitial}-${regionCode}-013')
output peMonitorName string = toLower('pep-${sanitizedAppName}-${environmentInitial}-${regionCode}-014')

output vnetNsgName string = toLower('${resourceAbbreviations.networkNetworkSecurityGroups}-${sanitizedAppName}-${environmentInitial}-${regionCode}-001')

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
// Application Gateway resource names
// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
output appGatewayName string = toLower('${resourceAbbreviations.networkApplicationGateways}${sanitizedAppName}-${environmentInitial}${resourceTokenWithDash}${dashRegionDashInstance}')
output appGatewayWafPolicyName string = toLower('${resourceAbbreviations.networkFirewallPoliciesWebApplication}-${sanitizedAppName}-${environmentInitial}${resourceTokenWithDash}${dashRegionDashInstance}')
output appGatewayPublicIpName string = toLower('${resourceAbbreviations.networkPublicIPAddresses}${sanitizedAppName}-agw-${environmentInitial}${resourceTokenWithDash}${dashRegionDashInstance}')

// Monitoring and Alerting resource names
output actionGroupName string             = toLower('${resourceAbbreviations.insightsActionGroups}${sanitizedAppName}-${environmentInitial}${resourceTokenWithDash}${dashRegionDashInstance}')
output smartDetectorAlertRuleName string  = toLower('${resourceAbbreviations.insightsSmartDetectorAlertRules}${sanitizedAppName}-${environmentInitial}${resourceTokenWithDash}${dashRegionDashInstance}')
