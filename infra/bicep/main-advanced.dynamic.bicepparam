// --------------------------------------------------------------------------------
// This file contains the parameters for the Bicep deployment.
// Note: This is dynamically modified by the build process.
// Anything that starts with a # and a { is a variable that will be replaced at runtime.
// --------------------------------------------------------------------------------
// The following values should be defined in GitHub Secrets or Environment Variables:
//   APP_NAME          - GH Repository Variable - no need to override
//   AGW_CERT          - GH Env Secret - AGW Certificate - BYO Certificate
//   ADMIN_PW          - GH Env Secret - Jump Box Admin Password - BYO Password
//   USER_PRINCIPAL_ID - GH Env Secret - User Principal ID - this is you - BYO User
//   runBuildDeployAPI - Runtime  - User decision to deploy webapp or not
//   envCode           - Runtime  - Environment Code (e.g., dev, qa, prod)
// --------------------------------------------------------------------------------

using './main-advanced.bicep'

param applicationName = '#{APP_NAME}#'
param environmentName = '#{envCode}#'
param principalId = '#{USER_PRINCIPAL_ID}#'
param deployUIApp = #{runBuildDeployUI}#  // Should we deploy the web app?

param openAI_deploy_location = '#{OPENAI_DEPLOY_LOCATION}#'
param appendResourceTokens = false
param addRoleAssignments = #{addRoleAssignments}#
param createDnsZones = #{createDnsZones}#
param publicAccessEnabled = #{publicAccessEnabled}#
param myIpAddress = '#{ADMIN_IP_ADDRESS}#'
param deployAIHub = #{deployAIHub}#
param deployBatchApp = #{deployBatchApp}#

// param existingVnetName = '#{APP_NAME_NO_DASHES}#-vnet-#{envCode}#'
// param existingVnetResourceGroupName = '#{RESOURCEGROUP_PREFIX}#-#{envCode}#'
// param vnetPrefix = '10.2.0.0/16'
// param subnet1Name = ''
// param subnet1Prefix = '10.2.0.64/26'
// param subnet2Name = ''
// param subnet2Prefix = '10.2.2.0/23'

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
