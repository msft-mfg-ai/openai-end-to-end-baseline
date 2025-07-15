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
param environmentName = '#{envCode}#'
param principalId = '#{USER_PRINCIPAL_ID}#'
param instanceNumber = '#{INSTANCE_NUMBER}#'
param regionCode = '#{GLOBAL_REGION_CODE}#' 
// param applicationId = '#{APP_ID}#'
// param ownerEmailTag = '#{OWNER_EMAIL}#' 
// param requestorName= '#{requestorName}#'
// param costCenterTag = 'CC'

param gpt40_DeploymentCapacity = #{AI_MODEL_CAPACITY}#
param gpt41_DeploymentCapacity = #{AI_MODEL_CAPACITY}#

param apimBaseUrl = '#{APIM_BASE_URL}#'
param apimAccessUrl = '#{APIM_ACCESS_URL}#'
@secure()
param apimAccessKey = '#{APIM_ACCESS_KEY}#'

param entraTenantId = '#{ENTRA_TENANT_ID}#'
param entraApiAudience = '#{ENTRA_API_AUDIENCE}#'
param entraScopes = '#{ENTRA_SCOPES}#'
param entraRedirectUri = '#{ENTRA_REDIRECT_URI}#'
@secure()
param entraClientId = '#{ENTRA_CLIENT_ID}#'
@secure()
param entraClientSecret = '#{ENTRA_CLIENT_SECRET}#'

param addRoleAssignments = #{addRoleAssignments}#
param publicAccessEnabled = true

param deployAIHub = #{deployAIHub}#
param deployAPIM = #{deployAPIM}#
param deployAPIApp = #{deployAPI}#  // Should we deploy the API app?
param deployUIApp = #{deployUI}#  // Should we deploy the UI app?
