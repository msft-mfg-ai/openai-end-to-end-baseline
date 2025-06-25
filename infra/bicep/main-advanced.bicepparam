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
// DEPLOYMENTCOUNT - number of the resource group that will be created
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
param deploymentCount = '#DEPLOYMENTCOUNT#'

//commenting out the role assignment parameters as they are not used in this deployment
//param addRoleAssignments = #{addRoleAssignments}#
param createDnsZones = true
param publicAccessEnabled = false

param admin_username = '#{ADMIN_USERNAME}#' // This is the username for the admin user of jumpboxvm
param admin_password = '#{ADMIN_PASSWORD}#' // This is the password for the admin user of jumpboxvm
param vm_name = '#{VM_NAME}#' // optional Jumpbox VM name - otherwise created by resourceNames.bicep
param myIpAddress = '#{MY_IP_ADDRESS}#'

param openAI_deploy_location = '#{OPENAI_DEPLOY_LOCATION}#'
param deployAIHub = true
//added the '' in between the parameters
//param deployAPIM = #{deployAPIM}#

param deployAPIM = true
param deployAPIApp = true  // Should we deploy the API app?
param deployUIApp = true // Should we deploy the UI app?
