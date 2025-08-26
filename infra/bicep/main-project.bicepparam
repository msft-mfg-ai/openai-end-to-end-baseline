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
//   environmentName     - Runtime  - Environment Code (e.g., dev, qa, prod)
// --------------------------------------------------------------------------------

using './main-project.bicep'

param projectResourceGroupName = '#{RESOURCEGROUPNAME}#'
param projectNumber = empty('#{projectNumber}#') ? null : int('#{projectNumber}#')
param projectName = '#{projectName}#'

param existingAiCentralAppName = '#{APP_NAME}#'
param existingAiCentralResourceGroupName = '#{ROOTRESOURCEGROUPNAME}#'

param environmentName = '#{envCode}#'
param location = empty('#{RESOURCEGROUP_LOCATION}#') ? null : '#{RESOURCEGROUP_LOCATION}#'

param myIpAddress = empty('#{MY_IP_ADDRESS}#') ? null : '#{MY_IP_ADDRESS}#'
param principalId = '#{USER_PRINCIPAL_ID}#'

param regionCode = '#{GLOBAL_REGION_CODE}#'
param instanceNumber = '#{INSTANCE_NUMBER}#'

param businessOwnerTag  = '#{BUSINESS_OWNER}#'
param requestorNameTag  = '#{REQUESTOR_NAME}#'
param primarySupportProviderTag  = '#{PRIMARY_SUPPORT_PROVIDER}#'
param applicationOwnerTag  = '#{APPLICATION_OWNER}#'
param costCenterTag  = '#{COST_CENTER}#'
param ltiServiceClassTag  = '#{LTI_SERVICE_CLASS}#'
param requestNumberTag  = '#{REQUEST_NUMBER}#'

param createDnsZones = true
param publicAccessEnabled = false

param admin_username = empty('#{ADMIN_USERNAME}#') ? null : '#{ADMIN_USERNAME}#' // This is the username for the admin user of jumpboxvm
param admin_password = empty('#{ADMIN_PASSWORD}#') ? null : '#{ADMIN_PASSWORD}#' // This is the password for the admin user of jumpboxvm
param vm_name = empty('#{VM_NAME}#') ? null : '#{VM_NAME}#' // optional Jumpbox VM name - otherwise created by resourceNames.bicep

param existingVnetName = empty('#{VNET_RESOURCE_NAME}#') ? null : '#{VNET_RESOURCE_NAME}#'
