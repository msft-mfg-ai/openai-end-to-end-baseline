@maxLength(32)
param appName string
param managedEnvironmentName string
param managedEnvironmentRg string
@description('Full image name including tag, e.g. "myregistry.azurecr.io/myapp:latest"')
param imageName string?
param registryName string
param userAssignedIdentityName string
param workloadProfileName string

@description('The target port for the container')
param targetPort int = 80

param location string = resourceGroup().location
param tags object = {}

@description('The secrets required for the container, with the key being the secret name and the value being the key vault URL')
@secure()
param secrets object = {}

@description('The environment variables for the container')
param env array = []

// --------------------------------------------------------------------------------------------------------------
resource containerAppEnvironmentResource 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: managedEnvironmentName
  scope: resourceGroup(managedEnvironmentRg)
}

resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: userAssignedIdentityName
}


resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: appName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: { '${userIdentity.id}': {} }
  }
  
  properties: {
    managedEnvironmentId: containerAppEnvironmentResource.id
    configuration: {
      ingress: {
        external: true
        targetPort: targetPort
        transport: 'auto'
      }
      registries: [
        {
          identity: userIdentity.id
          server: '${registryName}.azurecr.io'
        }
      ]
      secrets: [for secret in items(secrets): {
        name: secret.key
        identity: userIdentity.id
        keyVaultUrl: secret.value
      }]
    }
    template: {
      containers: [
        {
          name: 'app'
          image: imageName ?? 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          env: env
          resources: {
            cpu: json('0.5')
            memory: '1.0Gi'
          }
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/healthz/live'
                port: targetPort
              }
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/healthz/ready'
                port: targetPort
              }
            }
            {
              type: 'Startup'
              httpGet: {
                path: '/healthz/startup'
                port: targetPort
              }
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
      }
    }
    workloadProfileName: workloadProfileName
  }
}

// --------------------------------------------------------------------------------------------------------------
// Outputs
// --------------------------------------------------------------------------------------------------------------
output id string = containerApp.id
output name string = containerApp.name
output fqdn string = containerApp.properties.configuration.ingress.fqdn
