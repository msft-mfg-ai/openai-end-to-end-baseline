extension microsoftGraphV1

@description('The name of the Entra application')
param entraAppUniqueName string

@description('The display name of the Entra application')
param entraAppDisplayName string

@description('Tenant ID where the application is registered')
param tenantId string = tenant().tenantId

@description('The principle id of the user-assigned managed identity')
param userAssignedIdentityPrincipleId string

@description('The OAuth callback URL for the API Management service')
param OauthCallback string

var loginEndpoint = environment().authentication.loginEndpoint
var issuer = '${loginEndpoint}${tenantId}/v2.0'

resource entraResourceApp 'Microsoft.Graph/applications@v1.0' = {
  displayName: entraAppDisplayName
  uniqueName: entraAppUniqueName

  web: {
    redirectUris: [
      OauthCallback
    ]
  }
  // Application passwords are not supported for applications and service principals
  // https://learn.microsoft.com/en-us/graph/templates/bicep/limitations?view=graph-bicep-1.0#application-passwords-are-not-supported-for-applications-and-service-principals
  // passwordCredentials: [
  //   {
  //     displayName: 'entraResourceAppPassword'
  //     endDateTime: '2025-12-31T23:59:59Z'
  //     startDateTime: format(now, 'yyyy-MM-ddTHH:mm:ssZ')
  //   }
  // ]
  requiredResourceAccess: [
    {
      resourceAppId: '00000003-0000-0000-c000-000000000000' // Microsoft Graph
      resourceAccess: [
        {
          id: 'e1fe6dd8-ba31-4d61-89e7-88639da4683d'
          type: 'Scope'
        }
      ]
    }
    {
      resourceAppId: '499b84ac-1321-427f-aa17-267ca6975798' // ADO
      resourceAccess: [
        {
          id: 'ee69721e-6c3a-468f-a9ec-302d16a4c599'
          type: 'Scope'
        }
      ]
    }
  ]

  resource fic 'federatedIdentityCredentials@v1.0' = {
    name: '${entraResourceApp.uniqueName}/msiAsFic'
    description: 'Trust the user-assigned MI as a credential for the app'
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: issuer
    subject: userAssignedIdentityPrincipleId
  }
}

resource microsoftGraphServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' existing = {
  appId: '00000003-0000-0000-c000-000000000000'
}

resource adoServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' existing = {
  appId: '499b84ac-1321-427f-aa17-267ca6975798' // Azure DevOps
}

resource applicationRegistrationServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: entraResourceApp.appId
}

resource grants 'Microsoft.Graph/oauth2PermissionGrants@v1.0' = {
  clientId: applicationRegistrationServicePrincipal.id
  consentType: 'AllPrincipals'
  resourceId: microsoftGraphServicePrincipal.id
  scope: 'User.Read'
}

resource devopsGrant 'Microsoft.Graph/oauth2PermissionGrants@v1.0' = {
  clientId: applicationRegistrationServicePrincipal.id
  consentType: 'AllPrincipals'
  resourceId: adoServicePrincipal.id
  scope: 'user_impersonation'
}

// Outputs
output entraAppId string = entraResourceApp.appId
output entraAppTenantId string = tenantId
