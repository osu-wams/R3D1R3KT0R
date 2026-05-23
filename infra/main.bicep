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

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: location
}

module resources './resources.bicep' = {
  name: 'resources'
  scope: rg
  params: {
    location: location
    lawName: lawName
    acrName: acrName
    uamiName: uamiName
    acaEnvName: acaEnvName
    acaAppName: acaAppName
    containerImage: containerImage
  }
}

output acrLoginServer string = resources.outputs.acrLoginServer
output resourceGroupName string = rg.name
output containerAppName string = resources.outputs.containerAppName
