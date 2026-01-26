// Azure Managed Redis (v2 with RediSearch support)
// Based on: https://github.com/tfindelkind-redis/azure-managed-redis-terraform
// IMPORTANT: RediSearch requires Enterprise clustering policy

@description('Name of the Redis Enterprise cluster')
param name string

@description('Azure region for the resource')
param location string

@description('SKU name - supports both new Balanced_B* and legacy Enterprise_E* formats')
@allowed([
  // New Azure Managed Redis SKUs (v2)
  'Balanced_B0'
  'Balanced_B1'
  'Balanced_B3'
  'Balanced_B5'
  'Balanced_B10'
  'Balanced_B20'
  'Balanced_B50'
  'Balanced_B100'
  'Balanced_B150'
  'Balanced_B250'
  'Balanced_B350'
  'Balanced_B500'
  'Balanced_B700'
  'Balanced_B1000'
  // Memory Optimized SKUs
  'MemoryOptimized_M10'
  'MemoryOptimized_M20'
  'MemoryOptimized_M50'
  'MemoryOptimized_M100'
  'MemoryOptimized_M150'
  'MemoryOptimized_M250'
  'MemoryOptimized_M350'
  'MemoryOptimized_M500'
  'MemoryOptimized_M700'
  'MemoryOptimized_M1000'
  'MemoryOptimized_M1500'
  'MemoryOptimized_M2000'
  // Flash Optimized SKUs
  'FlashOptimized_A250'
  'FlashOptimized_A500'
  'FlashOptimized_A700'
  'FlashOptimized_A1000'
  'FlashOptimized_A1500'
  'FlashOptimized_A2000'
  'FlashOptimized_A4500'
  // Legacy Enterprise SKUs (still supported)
  'Enterprise_E1'
  'Enterprise_E5'
  'Enterprise_E10'
  'Enterprise_E20'
  'Enterprise_E50'
  'Enterprise_E100'
  'Enterprise_E200'
  'Enterprise_E400'
])
param skuName string = 'Balanced_B5'

@description('Clustering policy - MUST be EnterpriseCluster for RediSearch')
@allowed(['EnterpriseCluster', 'OSSCluster'])
param clusteringPolicy string = 'EnterpriseCluster'

@description('Enable high availability')
param highAvailability bool = true

@description('Minimum TLS version')
@allowed(['1.0', '1.1', '1.2'])
param minimumTlsVersion string = '1.2'

@description('Enable access keys authentication')
param accessKeysAuthenticationEnabled bool = true

@description('Eviction policy for the database')
@allowed(['NoEviction', 'AllKeysLRU', 'AllKeysRandom', 'VolatileLRU', 'VolatileRandom', 'VolatileTTL', 'AllKeysLFU', 'VolatileLFU'])
param evictionPolicy string = 'NoEviction'

@description('Tags to apply to resources')
param tags object = {}

// Determine if using new v2 SKU format (Balanced_*, MemoryOptimized_*, FlashOptimized_*)
var isV2Sku = startsWith(skuName, 'Balanced_') || startsWith(skuName, 'MemoryOptimized_') || startsWith(skuName, 'FlashOptimized_')

// Redis Enterprise Cluster - Using 2025-05-01-preview API for v2 support
resource redisEnterprise 'Microsoft.Cache/redisEnterprise@2025-05-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: isV2Sku ? 'v2' : null
  identity: {
    type: 'None'
  }
  properties: {
    minimumTlsVersion: minimumTlsVersion
    highAvailability: highAvailability ? 'Enabled' : 'Disabled'
  }
}

// Database resource with parent reference (matching Azure portal export pattern)
resource database 'Microsoft.Cache/redisEnterprise/databases@2025-05-01-preview' = {
  parent: redisEnterprise
  name: 'default'
  properties: {
    clientProtocol: 'Encrypted'
    port: 10000
    clusteringPolicy: clusteringPolicy
    evictionPolicy: evictionPolicy
    persistence: {
      aofEnabled: false
      rdbEnabled: false
    }
    deferUpgrade: 'NotDeferred'
    accessKeysAuthentication: accessKeysAuthenticationEnabled ? 'Enabled' : 'Disabled'
    modules: [
      { name: 'RediSearch' }
      { name: 'RedisJSON' }
      { name: 'RedisTimeSeries' }
      { name: 'RedisBloom' }
    ]
  }
}

output id string = redisEnterprise.id
output name string = redisEnterprise.name
output hostName string = redisEnterprise.properties.hostName
output databaseId string = database.id

// Output the primary key directly from the database resource
// This ensures the key is only retrieved AFTER the database is fully provisioned
// Critical: This avoids race conditions when using existing resource references in main.bicep
@secure()
output primaryKey string = database.listKeys().primaryKey
