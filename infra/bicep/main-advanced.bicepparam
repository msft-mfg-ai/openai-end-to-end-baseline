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

using './main-advanced.bicep'

// TODO: use readEnvironmentVariable() instead of tokens

param applicationName = '#{APP_NAME}#'
param environmentName = '#{envCode}#'
param principalId = '#{USER_PRINCIPAL_ID}#'
param instanceNumber = '#{INSTANCE_NUMBER}#'
param regionCode = '#{GLOBAL_REGION_CODE}#' 

param businessOwnerTag  = '#{BUSINESS_OWNER}#'
param requestorNameTag  = '#{REQUESTOR_NAME}#'
param primarySupportProviderTag  = '#{PRIMARY_SUPPORT_PROVIDER}#'
param applicationOwnerTag  = '#{APPLICATION_OWNER}#'
param costCenterTag  = '#{COST_CENTER}#'
param ltiServiceClassTag  = '#{LTI_SERVICE_CLASS}#'
param requestNumberTag  = '#{REQUEST_NUMBER}#'

param gpt40_DeploymentCapacity = empty('#{AI_MODEL_CAPACITY}#') ? null : int('#{AI_MODEL_CAPACITY}#')
param gpt41_DeploymentCapacity = empty('#{AI_MODEL_CAPACITY}#') ? null : int('#{AI_MODEL_CAPACITY}#')

param apimBaseUrl = empty('#{APIM_BASE_URL}#') ? null : '#{APIM_BASE_URL}#'
param apimAccessUrl = empty('#{APIM_ACCESS_URL}#') ? null : '#{APIM_ACCESS_URL}#'
param apimAccessKey = empty('#{APIM_ACCESS_KEY}#') ? null : '#{APIM_ACCESS_KEY}#'

param entraTenantId = empty('#{ENTRA_TENANT_ID}#') ? null : '#{ENTRA_TENANT_ID}#'
param entraApiAudience = empty('#{ENTRA_API_AUDIENCE}#') ? null : '#{ENTRA_API_AUDIENCE}#'
param entraScopes = empty('#{ENTRA_SCOPES}#') ? null : '#{ENTRA_SCOPES}#'
param entraRedirectUri = empty('#{ENTRA_REDIRECT_URI}#') ? null : '#{ENTRA_REDIRECT_URI}#'
@secure()
param entraClientId = empty('#{ENTRA_CLIENT_ID}#') ? null : '#{ENTRA_CLIENT_ID}#'
@secure()
param entraClientSecret = empty('#{ENTRA_CLIENT_SECRET}#') ? null : '#{ENTRA_CLIENT_SECRET}#'

param addRoleAssignments = empty('#{addRoleAssignments}#') ? false : toLower('#{addRoleAssignments}#') == 'true'
param createDnsZones = true
param publicAccessEnabled = false

param admin_username = empty('#{ADMIN_USERNAME}#') ? null : '#{ADMIN_USERNAME}#' // This is the username for the admin user of jumpboxvm
param admin_password = empty('#{ADMIN_PASSWORD}#') ? null : '#{ADMIN_PASSWORD}#' // This is the password for the admin user of jumpboxvm
param vm_name = empty('#{VM_NAME}#') ? null : '#{VM_NAME}#' // optional Jumpbox VM name - otherwise created by resourceNames.bicep
param myIpAddress = empty('#{MY_IP_ADDRESS}#') ? null : '#{MY_IP_ADDRESS}#'

param aiFoundry_deploy_location = empty('#{AIFOUNDRY_DEPLOY_LOCATION}#') ? null : '#{AIFOUNDRY_DEPLOY_LOCATION}#'
param deployAIFoundry = true
param deployAPIM = empty('#{deployAPIM}#') ? false : toLower('#{deployAPIM}#') == 'true'
// Should we deploy the API Management service?
param deployAPIApp = empty('#{deployAPI}#') ? false : toLower('#{deployAPI}#') == 'true'
// Should we deploy the API app?
param deployUIApp = empty('#{deployUI}#') ? false : toLower('#{deployUI}#') == 'true'
// Should we deploy the UI app?
param vnetPrefix = empty('#{VNET_PREFIX}#') ? null : '#{VNET_PREFIX}#'

// applications
param apiImageName = empty('#{API_IMAGE_NAME}#') ? null : '#{API_IMAGE_NAME}#'
param uiImageName = empty('#{UI_IMAGE_NAME}#') ? null : '#{UI_IMAGE_NAME}#'

// only for Microsoft internal deployments
param mockUserUpn = empty('#{MOCK_USER_UPN}#') ? false : toLower('#{MOCK_USER_UPN}#') == 'true' // Mock user UPN for testing purposes

// use consumption for non-customer deployments
param containerAppEnvironmentWorkloadProfiles = [
  {
    name: 'consumption'
    workloadProfileType: 'consumption'
  }
]
