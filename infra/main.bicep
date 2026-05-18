targetScope = 'subscription'

@description('Azure region for all resources.')
param location string = 'eastus'

@description('Base name used to derive all resource names.')
param environmentName string = 'r3d1r3kt0r'

@description('Container image to deploy. Managed by CI via az containerapp update after first boot.')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

var rgName     = 'rg-${environmentName}'
var lawName    = 'law-${environmentName}'
var acrName    = replace('acr${environmentName}', '-', '')
var uamiName   = 'id-${environmentName}'
var acaEnvName = 'acaenv-${environmentName}'
var acaAppName = environmentName

// AcrPull built-in role definition ID (constant across all tenants)
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: location
}

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: lawName
  location: location
  scope: rg
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  scope: rg
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: uamiName
  location: location
  scope: rg
}

// Deterministic GUID ensures idempotent role assignment across re-deployments
resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, uami.id, acrPullRoleId)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource acaEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: acaEnvName
  location: location
  scope: rg
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: law.properties.customerId
        sharedKey: law.listKeys().primarySharedKey
      }
    }
  }
}

resource acaApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: acaAppName
  location: location
  scope: rg
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: acaEnv.id
    configuration: {
      activeRevisionsMode: 'Single'
      registries: [
        {
          server: acr.properties.loginServer
          identity: uami.id
        }
      ]
      ingress: {
        external: true
        targetPort: 80
        transport: 'http'
        allowInsecure: false
      }
    }
    template: {
      containers: [
        {
          name: acaAppName
          image: containerImage
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}

output acrLoginServer string = acr.properties.loginServer
output resourceGroupName string = rg.name
output containerAppName string = acaApp.name
