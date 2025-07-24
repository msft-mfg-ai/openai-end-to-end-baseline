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

param entraTenantId = empty('#{ENTRA_TENANT_ID}#') ? null : '#{ENTRA_TENANT_ID}#'
param entraApiAudience = empty('#{ENTRA_API_AUDIENCE}#') ? null : '#{ENTRA_API_AUDIENCE}#'
param entraScopes = empty('#{ENTRA_SCOPES}#') ? null : '#{ENTRA_SCOPES}#'
param entraRedirectUri = empty('#{ENTRA_REDIRECT_URI}#') ? null : '#{ENTRA_REDIRECT_URI}#'
@secure()
param entraClientId = empty('#{ENTRA_CLIENT_ID}#') ? null : '#{ENTRA_CLIENT_ID}#'
@secure()
param entraClientSecret = empty('#{ENTRA_CLIENT_SECRET}#') ? null : '#{ENTRA_CLIENT_SECRET}#'


param addRoleAssignments = #{addRoleAssignments}#
param publicAccessEnabled = true

param aiFoundry_deploy_location = empty('#{AIFOUNDRY_DEPLOY_LOCATION}#') ? null : '#{AIFOUNDRY_DEPLOY_LOCATION}#'
param deployAIFoundry = true
param deployAPIM = #{deployAPIM}#
param deployAPIApp = #{deployAPI}#  // Should we deploy the API app?
param deployUIApp = #{deployUI}#  // Should we deploy the UI app?

// applications
param apiImageName = empty('#{API_IMAGE_NAME}#') ? null : '#{API_IMAGE_NAME}#'
param uiImageName = empty('#{UI_IMAGE_NAME}#') ? null : '#{UI_IMAGE_NAME}#'

// use consumption for non-customer deployments
param containerAppEnvironmentWorkloadProfiles = [
  {
    name: 'consumption'
    workloadProfileType: 'consumption'
  }
]
