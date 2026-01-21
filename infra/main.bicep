targetScope = 'subscription'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Azure region for all resources')
param location string = 'westus3'

@description('Unique environment name (e.g., student name or random suffix)')
param environmentName string = 'workshop'

@description('Tags to apply to all resources')
param tags object = {}

@description('Redis SKU (B3 = 3GB minimum for RediSearch)')
param redisSku string = 'Balanced_B3'

@description('Use placeholder images for initial deployment (set to false after images are pushed to ACR)')
param usePlaceholderImages bool = true

// ============================================================================
// VARIABLES
// ============================================================================

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

var resourceGroupName = '${abbrs.resourcesResourceGroups}${environmentName}'
var vnetName = '${abbrs.networkVirtualNetworks}${resourceToken}'
var logAnalyticsName = '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
var containerAppsEnvName = '${abbrs.appManagedEnvironments}${resourceToken}'
var acrName = '${abbrs.containerRegistryRegistries}${resourceToken}'
var redisName = '${abbrs.cacheRedisEnterprise}${resourceToken}'
var identityName = '${abbrs.managedIdentityUserAssignedIdentities}${resourceToken}'
var storageName = '${abbrs.storageStorageAccounts}${resourceToken}'

// Private DNS Zone names
var redisDnsZoneName = 'privatelink.redis.cache.windows.net'
var acrDnsZoneName = 'privatelink.azurecr.io'

// ============================================================================
// RESOURCE GROUP
// ============================================================================

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
  tags: union(tags, { 'azd-env-name': environmentName })
}

// ============================================================================
// NETWORKING
// ============================================================================

module vnet 'modules/virtual-network.bicep' = {
  name: 'vnet-deployment'
  scope: rg
  params: {
    name: vnetName
    location: location
    tags: tags
  }
}

// Private DNS Zones
module redisDnsZone 'modules/private-dns-zone.bicep' = {
  name: 'redis-dns-zone-deployment'
  scope: rg
  params: {
    name: redisDnsZoneName
    vnetId: vnet.outputs.vnetId
    tags: tags
  }
}

module acrDnsZone 'modules/private-dns-zone.bicep' = {
  name: 'acr-dns-zone-deployment'
  scope: rg
  params: {
    name: acrDnsZoneName
    vnetId: vnet.outputs.vnetId
    tags: tags
  }
}

// ============================================================================
// MANAGED IDENTITY
// ============================================================================

module identity 'modules/managed-identity.bicep' = {
  name: 'identity-deployment'
  scope: rg
  params: {
    name: identityName
    location: location
    tags: tags
  }
}

// ============================================================================
// STORAGE ACCOUNT (Azure Files for live code editing)
// ============================================================================

module storage 'modules/storage-account.bicep' = {
  name: 'storage-deployment'
  scope: rg
  params: {
    name: storageName
    location: location
    tags: tags
    shareName: 'modules'
  }
}

// ============================================================================
// CONTAINER REGISTRY
// ============================================================================

module acr 'modules/container-registry.bicep' = {
  name: 'acr-deployment'
  scope: rg
  params: {
    name: acrName
    location: location
    tags: tags
  }
}

// ACR Private Endpoint
module acrPrivateEndpoint 'modules/private-endpoint.bicep' = {
  name: 'acr-pe-deployment'
  scope: rg
  params: {
    name: '${abbrs.networkPrivateEndpoints}acr-${resourceToken}'
    location: location
    tags: tags
    subnetId: vnet.outputs.privateEndpointsSubnetId
    privateLinkServiceId: acr.outputs.id
    groupIds: ['registry']
    privateDnsZoneId: acrDnsZone.outputs.id
  }
}

// ACR Pull role assignment for managed identity
module acrRoleAssignment 'modules/role-assignment.bicep' = {
  name: 'acr-role-assignment'
  scope: rg
  params: {
    principalId: identity.outputs.principalId
    acrId: acr.outputs.id
  }
}

// ============================================================================
// AZURE MANAGED REDIS
// ============================================================================

module redis 'modules/redis-enterprise.bicep' = {
  name: 'redis-deployment'
  scope: rg
  params: {
    name: redisName
    location: location
    tags: tags
    skuName: redisSku
    clusteringPolicy: 'EnterpriseCluster' // REQUIRED for RediSearch
  }
}

// Redis Private Endpoint
module redisPrivateEndpoint 'modules/private-endpoint.bicep' = {
  name: 'redis-pe-deployment'
  scope: rg
  params: {
    name: '${abbrs.networkPrivateEndpoints}redis-${resourceToken}'
    location: location
    tags: tags
    subnetId: vnet.outputs.privateEndpointsSubnetId
    privateLinkServiceId: redis.outputs.id
    groupIds: ['redisEnterprise']
    privateDnsZoneId: redisDnsZone.outputs.id
  }
}

// ============================================================================
// LOG ANALYTICS & CONTAINER APPS ENVIRONMENT
// ============================================================================

module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'log-analytics-deployment'
  scope: rg
  params: {
    name: logAnalyticsName
    location: location
    tags: tags
  }
}

module containerAppsEnv 'modules/container-apps-environment.bicep' = {
  name: 'cae-deployment'
  scope: rg
  params: {
    name: containerAppsEnvName
    location: location
    tags: tags
    infrastructureSubnetId: vnet.outputs.containerAppsSubnetId
    logAnalyticsCustomerId: logAnalytics.outputs.customerId
    logAnalyticsSharedKey: logAnalytics.outputs.primarySharedKey
    internal: false // External ingress for UI
  }
}

// ============================================================================
// CONTAINER APPS
// ============================================================================

// Get Redis access key for secrets
resource redisResource 'Microsoft.Cache/redisEnterprise@2024-02-01' existing = {
  name: redisName
  scope: rg
}

resource redisDatabase 'Microsoft.Cache/redisEnterprise/databases@2024-02-01' existing = {
  name: 'default'
  parent: redisResource
}

// Generator App
module generatorApp 'modules/container-app.bicep' = {
  name: 'generator-app-deployment'
  scope: rg
  dependsOn: [acrRoleAssignment, redisPrivateEndpoint, acrPrivateEndpoint]
  params: {
    name: 'generator'
    location: location
    tags: union(tags, { 'azd-service-name': 'generator' })
    containerAppsEnvironmentId: containerAppsEnv.outputs.id
    imageName: '${acr.outputs.loginServer}/generator:latest'
    registryServer: acr.outputs.loginServer
    identityId: identity.outputs.id
    usePlaceholderImage: usePlaceholderImages
    externalIngress: false
    minReplicas: 1
    maxReplicas: 1
    cpu: '0.25'
    memory: '0.5Gi'
    secrets: [
      {
        name: 'redis-password'
        value: redisDatabase.listKeys().primaryKey
      }
    ]
    env: [
      { name: 'REDIS_HOST', value: redis.outputs.hostName }
      { name: 'REDIS_PORT', value: '10000' }
      { name: 'REDIS_SSL', value: 'true' }
      { name: 'REDIS_PASSWORD', secretRef: 'redis-password' }
      { name: 'LOG_LEVEL', value: 'INFO' }
    ]
  }
}

// Processor App (with Azure Files mount for live code editing)
module processorApp 'modules/container-app-with-storage.bicep' = {
  name: 'processor-app-deployment'
  scope: rg
  dependsOn: [acrRoleAssignment, redisPrivateEndpoint, acrPrivateEndpoint]
  params: {
    name: 'processor'
    location: location
    tags: union(tags, { 'azd-service-name': 'processor' })
    containerAppsEnvironmentId: containerAppsEnv.outputs.id
    imageName: '${acr.outputs.loginServer}/processor:latest'
    registryServer: acr.outputs.loginServer
    identityId: identity.outputs.id
    usePlaceholderImage: usePlaceholderImages
    cpu: '0.5'
    memory: '1Gi'
    storageAccountName: storage.outputs.name
    storageAccountKey: storage.outputs.accessKey
    shareName: storage.outputs.shareName
    mountPath: '/app/processor/modules'
    secrets: [
      {
        name: 'redis-password'
        value: redisDatabase.listKeys().primaryKey
      }
    ]
    env: [
      { name: 'REDIS_HOST', value: redis.outputs.hostName }
      { name: 'REDIS_PORT', value: '10000' }
      { name: 'REDIS_SSL', value: 'true' }
      { name: 'REDIS_PASSWORD', secretRef: 'redis-password' }
      { name: 'LOG_LEVEL', value: 'INFO' }
    ]
  }
}

// API App (with storage mount for modules)
module apiApp 'modules/container-app-with-storage.bicep' = {
  name: 'api-app-deployment'
  scope: rg
  dependsOn: [acrRoleAssignment, redisPrivateEndpoint, acrPrivateEndpoint]
  params: {
    name: 'api'
    location: location
    tags: union(tags, { 'azd-service-name': 'api' })
    containerAppsEnvironmentId: containerAppsEnv.outputs.id
    imageName: '${acr.outputs.loginServer}/api:latest'
    registryServer: acr.outputs.loginServer
    identityId: identity.outputs.id
    usePlaceholderImage: usePlaceholderImages
    storageAccountName: storage.outputs.name
    storageAccountKey: storage.outputs.accessKey
    shareName: storage.outputs.shareName
    mountPath: '/app/processor/modules'
    externalIngress: true
    targetPort: 8000
    minReplicas: 1
    maxReplicas: 3
    cpu: '0.5'
    memory: '1Gi'
    secrets: [
      {
        name: 'redis-password'
        value: redisDatabase.listKeys().primaryKey
      }
    ]
    env: [
      { name: 'REDIS_HOST', value: redis.outputs.hostName }
      { name: 'REDIS_PORT', value: '10000' }
      { name: 'REDIS_SSL', value: 'true' }
      { name: 'REDIS_PASSWORD', secretRef: 'redis-password' }
      { name: 'LOG_LEVEL', value: 'INFO' }
    ]
  }
}

// Redis Insight App (uses public Docker Hub image, no ACR)
module redisInsightApp 'modules/redis-insight.bicep' = {
  name: 'redis-insight-app-deployment'
  scope: rg
  params: {
    name: 'redis-insight'
    location: location
    tags: union(tags, { 'azd-service-name': 'redis-insight' })
    containerAppsEnvironmentId: containerAppsEnv.outputs.id
    targetPort: 5540
    minReplicas: 1
    maxReplicas: 1
  }
}

// UI App (depends on API and Redis Insight for URLs)
module uiApp 'modules/container-app.bicep' = {
  name: 'ui-app-deployment'
  scope: rg
  dependsOn: [acrRoleAssignment, acrPrivateEndpoint]
  params: {
    name: 'ui'
    location: location
    tags: union(tags, { 'azd-service-name': 'ui' })
    containerAppsEnvironmentId: containerAppsEnv.outputs.id
    imageName: '${acr.outputs.loginServer}/ui:latest'
    registryServer: acr.outputs.loginServer
    identityId: identity.outputs.id
    usePlaceholderImage: usePlaceholderImages
    externalIngress: true
    targetPort: 80
    minReplicas: 1
    maxReplicas: 1
    cpu: '0.25'
    memory: '0.5Gi'
    env: [
      { name: 'API_BASE_URL', value: 'https://${apiApp.outputs.fqdn}' }
      { name: 'REDIS_INSIGHT_URL', value: 'https://${redisInsightApp.outputs.fqdn}' }
    ]
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_SUBSCRIPTION_ID string = subscription().subscriptionId
output AZURE_RESOURCE_GROUP string = rg.name

// Required by azd for container deployment
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.loginServer

output ACR_NAME string = acr.outputs.name
output ACR_LOGIN_SERVER string = acr.outputs.loginServer

output REDIS_HOST string = redis.outputs.hostName
output REDIS_PORT string = '10000'

output API_URL string = 'https://${apiApp.outputs.fqdn}'
output UI_URL string = 'https://${uiApp.outputs.fqdn}'
output REDIS_INSIGHT_URL string = 'https://${redisInsightApp.outputs.fqdn}'

output STORAGE_ACCOUNT_NAME string = storage.outputs.name
output STORAGE_SHARE_NAME string = storage.outputs.shareName
