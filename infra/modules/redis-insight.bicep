// Container App for Redis Insight (pulls from public Docker Hub)
// This is a separate module because Redis Insight uses a public image

@description('Name of the Container App')
param name string

@description('Azure region for the resource')
param location string

@description('Tags to apply to resources')
param tags object = {}

@description('ID of the Container Apps Environment')
param containerAppsEnvironmentId string

@description('Target port for the container')
param targetPort int = 5540

@description('Minimum number of replicas')
param minReplicas int = 1

@description('Maximum number of replicas')
param maxReplicas int = 1

@description('Workload profile to use')
param workloadProfileName string = 'Consumption'

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    workloadProfileName: workloadProfileName
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: targetPort
        transport: 'http'
        allowInsecure: false
      }
    }
    template: {
      containers: [
        {
          image: 'redis/redisinsight:latest'
          name: 'redis-insight'
          env: [
            { name: 'RI_APP_PORT', value: string(targetPort) }
          ]
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
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
output fqdn string = containerApp.properties.configuration.ingress.fqdn
