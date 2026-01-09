// Azure Managed Redis (Enterprise tier with RediSearch support)
// IMPORTANT: RediSearch requires Enterprise clustering policy

@description('Name of the Redis Enterprise cluster')
param name string

@description('Azure region for the resource')
param location string

@description('SKU name (e.g., Balanced_B3, Balanced_B6)')
@allowed(['Balanced_B0', 'Balanced_B1', 'Balanced_B3', 'Balanced_B5', 'Balanced_B10', 'Balanced_B20', 'Balanced_B50', 'Balanced_B100', 'Balanced_B150', 'Balanced_B250', 'Balanced_B350', 'Balanced_B500', 'Balanced_B700', 'Balanced_B1000', 'MemoryOptimized_M10', 'MemoryOptimized_M20', 'MemoryOptimized_M50', 'MemoryOptimized_M100', 'MemoryOptimized_M150', 'MemoryOptimized_M250', 'MemoryOptimized_M350', 'MemoryOptimized_M500', 'MemoryOptimized_M700', 'MemoryOptimized_M1000', 'MemoryOptimized_M1500', 'MemoryOptimized_M2000', 'ComputeOptimized_X3', 'ComputeOptimized_X5', 'ComputeOptimized_X10', 'ComputeOptimized_X20', 'ComputeOptimized_X50', 'ComputeOptimized_X100', 'ComputeOptimized_X150', 'ComputeOptimized_X250', 'ComputeOptimized_X350', 'ComputeOptimized_X500', 'ComputeOptimized_X700'])
param skuName string = 'Balanced_B3' // 3GB minimum for RediSearch

@description('Clustering policy - MUST be EnterpriseCluster for RediSearch')
@allowed(['EnterpriseCluster', 'OSSCluster'])
param clusteringPolicy string = 'EnterpriseCluster'

@description('Tags to apply to resources')
param tags object = {}

// Redis Enterprise Cluster - Using 2024-09-01-preview for Azure Managed Redis (AMR) Balanced SKUs
resource redisEnterprise 'Microsoft.Cache/redisEnterprise@2024-09-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  properties: {
    minimumTlsVersion: '1.2'
  }
}

// Redis Enterprise Database with modules
resource database 'Microsoft.Cache/redisEnterprise/databases@2024-09-01-preview' = {
  parent: redisEnterprise
  name: 'default'
  properties: {
    clientProtocol: 'Encrypted'
    port: 10000
    clusteringPolicy: clusteringPolicy
    evictionPolicy: 'NoEviction'
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

// Note: Access keys must be retrieved separately using listKeys()
// This is done in main.bicep to pass to Container Apps as secrets
