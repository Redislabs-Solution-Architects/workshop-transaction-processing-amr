// Container App with Azure Files volume mount for processor

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

@description('Azure Storage account name for file share')
param storageAccountName string

@description('Azure Storage account key')
@secure()
param storageAccountKey string

@description('Azure Files share name')
param shareName string

@description('Mount path in container')
param mountPath string = '/app/processor/modules'

@description('CPU allocation')
param cpu string = '0.5'

@description('Memory allocation')
param memory string = '1Gi'

@description('Workload profile to use')
param workloadProfileName string = 'Consumption'

@description('Whether to enable external ingress')
param externalIngress bool = false

@description('Target port for the container')
param targetPort int = 8000

@description('Minimum number of replicas')
param minReplicas int = 1

@description('Maximum number of replicas')
param maxReplicas int = 1

// Extract the environment name from the ID
var envName = last(split(containerAppsEnvironmentId, '/'))

// Reference existing storage link (created by cae-storage module to avoid race conditions)
resource containerAppsEnv 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: envName
}

resource storageLink 'Microsoft.App/managedEnvironments/storages@2024-03-01' existing = {
  parent: containerAppsEnv
  name: 'modules-storage'
}

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: name
  location: location
  tags: tags
  dependsOn: [storageLink]
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
      ingress: externalIngress ? {
        external: true
        targetPort: targetPort
        allowInsecure: false
        transport: 'http'
      } : null
      secrets: union(secrets, [
        {
          name: 'storage-account-key'
          value: storageAccountKey
        }
      ])
      registries: [
        {
          server: registryServer
          identity: identityId
        }
      ]
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
          volumeMounts: [
            {
              volumeName: 'modules-volume'
              mountPath: mountPath
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
      volumes: [
        {
          name: 'modules-volume'
          storageType: 'AzureFile'
          storageName: 'modules-storage'
        }
      ]
    }
  }
}

output id string = containerApp.id
output name string = containerApp.name
output fqdn string = externalIngress ? containerApp.properties.configuration.ingress.fqdn : ''
