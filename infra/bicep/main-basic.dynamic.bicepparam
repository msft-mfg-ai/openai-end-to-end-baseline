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

using './main-basic.bicep'

param applicationName = '#{APP_NAME}#'
param applicationId = '#{APP_ID}#'
param environmentName = '#{envCode}#'
param principalId = '#{USER_PRINCIPAL_ID}#'
param instanceNumber = '#{INSTANCE_NUMBER}#'
param ownerEmailTag = '#{OWNER_EMAIL}#' 
param requestorName= '#{requestorName}#'
param regionCode = '#{GLOBAL_REGION_CODE}#' 
param costCenterTag = 'CC'

param addRoleAssignments = #{addRoleAssignments}#
param createDnsZones = false
param publicAccessEnabled = true

param deployAIHub = #{deployAIHub}#
param deployAPIM = #{deployAPIM}#
param deployAPIApp = #{runBuildDeployAPI}#  // Should we deploy the web app?
