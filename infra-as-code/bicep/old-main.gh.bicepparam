// --------------------------------------------------------------------------------------------------------------
// The most minimal parameters you need - everything else is defaulted
// --------------------------------------------------------------------------------------------------------------
using 'main.bicep'

param applicationName = '#{APP_NAME}#'
param location = '#{RESOURCEGROUP_LOCATION}#'
param openAI_deploy_location = '#{OPENAI_DEPLOY_LOCATION}#'
param environmentName = '#{envCode}#'
param appendResourceTokens = false
param addRoleAssignments = #{addRoleAssignments}#
param createDnsZones = #{createDnsZones}#
param publicAccessEnabled = #{publicAccessEnabled}#
param myIpAddress = '#{ADMIN_IP_ADDRESS}#'
param principalId = '#{ADMIN_PRINCIPAL_ID}#'
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
