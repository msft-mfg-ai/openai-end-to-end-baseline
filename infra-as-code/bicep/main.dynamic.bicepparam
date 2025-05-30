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

using './main.bicep'

param baseName = '#{APP_NAME}##{envCode}#'
param appGatewayListenerCertificate = '#{AGW_CERT}#'
param jumpBoxAdminPassword = '#{ADMIN_PW}#'
param yourPrincipalId = '#{USER_PRINCIPAL_ID}#'
param deployWebApp = #{runBuildDeployAPI}#  // Should we deploy the web app?

// Hardcoded values for the deployment
param telemetryOptOut = true // do not deploy the Customer Attribution PID
param deployJumpBox = false  // do not deploy the Jump Box

// Optional future parameters to be overridden if needed
// param customDomainName = 'contoso.com'
// param publishFileName = 'chatui.zip'
