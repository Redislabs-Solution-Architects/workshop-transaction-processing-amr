// Generic Container App module

@description('Name of the Container App')
param name string

@description('Azure region for the resource')
param location string

@description('Tags to apply to resources')
param tags object = {}

@description('ID of the Container Apps Environment')
param containerAppsEnvironmentId string

@description('Container image to deploy')
param imageName string

@description('Container registry login server')
param registryServer string

@description('Use placeholder image for initial deployment (when ACR images do not exist yet)')
param usePlaceholderImage bool = false

// Placeholder image that always exists - used for initial deployment
var placeholderImage = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
var actualImage = usePlaceholderImage ? placeholderImage : imageName

@description('User-assigned managed identity ID for ACR pull')
param identityId string

@description('Environment variables for the container')
param env array = []

@description('Container secrets (array of objects with name and value)')
param secrets array = []

@description('Target port for the container')
param targetPort int = 8000

@description('Enable external ingress')
param externalIngress bool = false

@description('Minimum number of replicas')
param minReplicas int = 0

@description('Maximum number of replicas')
param maxReplicas int = 1

@description('CPU allocation (e.g., 0.5)')
param cpu string = '0.5'

@description('Memory allocation (e.g., 1Gi)')
param memory string = '1Gi'

@description('Workload profile to use')
param workloadProfileName string = 'Consumption'

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    workloadProfileName: workloadProfileName
    configuration: {
      activeRevisionsMode: 'Single'
      secrets: secrets
      registries: [
        {
          server: registryServer
          identity: identityId
        }
      ]
      ingress: externalIngress ? {
        external: true
        targetPort: targetPort
        transport: 'http'
        allowInsecure: false
      } : null
    }
    template: {
      containers: [
        {
          image: actualImage
          name: name
          env: env
          resources: {
            cpu: json(cpu)
            memory: memory
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}

output id string = containerApp.id
output name string = containerApp.name
output fqdn string = externalIngress ? containerApp.properties.configuration.ingress.fqdn : ''
output latestRevisionName string = containerApp.properties.latestRevisionName
