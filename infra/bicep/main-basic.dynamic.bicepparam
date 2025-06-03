// --------------------------------------------------------------------------------
// This file contains the parameters for the Bicep deployment.
// Note: This is dynamically modified by the build process.
// Anything that starts with a # and a { is a variable that will be replaced at runtime.
// --------------------------------------------------------------------------------
// The following values should be defined in GitHub Secrets or Environment Variables:
//   applicationName     - GH Repository Variable - no need to override
//   principalId         - GH Env Secret - User Principal ID - this is you - BYO User
//   runBuildDeployUI    - Runtime  - User decision to deploy webapp or not
//   environmentName     - Runtime  - Environment Code (e.g., dev, qa, prod)
// --------------------------------------------------------------------------------

using './main-basic.bicep'

param applicationName = '#{APP_NAME}#'
param environmentName = '#{envCode}#'
param principalId = '#{USER_PRINCIPAL_ID}#'
param deployUIApp = #{runBuildDeployUI}#  // Should we deploy the web app?

// Optional future parameters to be overridden if needed
// param customDomainName = 'contoso.com'
// param publishFileName = 'chatui.zip'
