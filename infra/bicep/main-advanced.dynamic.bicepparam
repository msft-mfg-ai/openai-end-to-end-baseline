// --------------------------------------------------------------------------------
// This file contains the parameters for the Bicep deployment.
// Note: This is dynamically modified by the build process.
// Anything that starts with a # and a { is a variable that will be replaced at runtime.
// --------------------------------------------------------------------------------
// The following values should be defined in GitHub Secrets or Environment Variables:
//   APP_NAME            - GH Repository Variable - no need to override
//   APP_ID              - GH Repository Variable - no need to override
//   USER_PRINCIPAL_ID   - GH Environment Secret - User Principal ID - this is you - BYO User
//   INSTANCE_NUMBER     - GH Environment Variable
//   OWNER_EMAIL         - GH Environment Variable - optional
//   runBuildDeployAPI    - Runtime  - User decision to deploy webapp or not
//   environmentName     - Runtime  - Environment Code (e.g., dev, qa, prod)
// --------------------------------------------------------------------------------

using './main-advanced.bicep'

param applicationName = '#{APP_NAME}#'
param applicationId = '#{APP_ID}#'
param environmentName = '#{envCode}#'
param principalId = '#{USER_PRINCIPAL_ID}#'
param instanceNumber = '#{INSTANCE_NUMBER}#'
param ownerEmailTag = '#{OWNER_EMAIL}#' 
param requestorName= '#{requestorName}#'
param regionCode = '#{GLOBAL_REGION_CODE}#' 
param costCenterTag = 'CC'
// param addRoleAssignments = '#{addRoleAssignments}#'
param createDnsZones = true // Should we create DNS zones?
param publicAccessEnabled = true // Should we enable public access to the web app?
param admin_username = '#{ADMIN_USERNAME}#' // This is the username for the admin user of jumpboxvm
param admin_password = '#{ADMIN_PASSWORD}#' // This is the password for the admin user of jumpboxvm

param deployAIHub = true
param deployAPIApp = false // Should we deploy the web app?
// param deployUIApp = #{runBuildDeployUI}#  // Should we deploy the web app?
// param deployBatchApp = #{deployBatchApp}#

// param openAI_deploy_location = '#{OPENAI_DEPLOY_LOCATION}#'
// param appendResourceTokens = false
// param myIpAddress = '#{ADMIN_IP_ADDRESS}#'

// param existingVnetName = '#{APP_NAME_NO_DASHES}#-vnet-#{envCode}#'
// param existingVnetResourceGroupName = '#{RESOURCEGROUP_PREFIX}#-#{envCode}#'
//param vnetPrefix = '10.2.0.0/16'
//param subnet1Name = 'subnet1dynamic'
//param subnet1Prefix = '10.2.0.64/26'
//param subnet2Name = 'subnet2dyanamic'
//param subnet2Prefix = '10.2.2.0/23'



// param existing_ACR_Name = '#{APP_NAME_NO_DASHES}#cr#{envCode}#'
// param existing_ACR_ResourceGroupName = '#{RESOURCEGROUP_PREFIX}#-#{envCode}#'

// param existing_CogServices_Name = '#{APP_NAME_NO_DASHES}#-cog-#{envCode}#'
// param existing_CogServices_ResourceGroupName = '#{RESOURCEGROUP_PREFIX}#-#{envCode}#'

// param existing_SearchService_Name = '#{APP_NAME_NO_DASHES}#-srch-#{envCode}#'
// param existing_SearchService_ResourceGroupName = '#{RESOURCEGROUP_PREFIX}#-#{envCode}#'

// param existing_Cosmos_Name = '#{APP_NAME_NO_DASHES}#-cosmos-#{envCode}#'
// param existing_Cosmos_ResourceGroupName = '#{RESOURCEGROUP_PREFIX}#-#{envCode}#'

// param existingKeyVaultName = '#{APP_NAME_NO_DASHES}#kv#{envCode}#'
// param existing_KeyVault_ResourceGroupName = '#{RESOURCEGROUP_PREFIX}#-#{envCode}#'

// param existing_LogAnalytics_Name = '#{APP_NAME_NO_DASHES}#-log-#{envCode}#'
// param existing_AppInsights_Name = '#{APP_NAME_NO_DASHES}#-appi-#{envCode}#'

// param existing_managedAppEnv_Name = '#{APP_NAME_NO_DASHES}#-cae-#{envCode}#'
