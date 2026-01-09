// Container Apps Environment with VNet integration

@description('Name of the Container Apps Environment')
param name string

@description('Azure region for the resource')
param location string

@description('Tags to apply to resources')
param tags object = {}

@description('Subnet ID for Container Apps infrastructure')
param infrastructureSubnetId string

@description('Log Analytics customer ID')
param logAnalyticsCustomerId string

@description('Log Analytics shared key')
@secure()
param logAnalyticsSharedKey string

@description('Whether the environment is internal-only (no public ingress)')
param internal bool = false

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsCustomerId
        sharedKey: logAnalyticsSharedKey
      }
    }
    vnetConfiguration: {
      internal: internal
      infrastructureSubnetId: infrastructureSubnetId
    }
    zoneRedundant: false
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

output id string = containerAppsEnvironment.id
output name string = containerAppsEnvironment.name
output defaultDomain string = containerAppsEnvironment.properties.defaultDomain
output staticIp string = containerAppsEnvironment.properties.staticIp
