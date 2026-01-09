// Azure Container Registry (Premium SKU required for Private Endpoint)

@description('Name of the container registry (must be globally unique)')
param name string

@description('Azure region for the resource')
param location string

@description('SKU for the container registry')
@allowed(['Basic', 'Standard', 'Premium'])
param sku string = 'Premium'

@description('Whether to allow public network access')
param publicNetworkAccess string = 'Enabled'

@description('Tags to apply to resources')
param tags object = {}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: true // Enable for initial image push, can disable later
    publicNetworkAccess: publicNetworkAccess
    networkRuleBypassOptions: 'AzureServices'
  }
}

output id string = acr.id
output name string = acr.name
output loginServer string = acr.properties.loginServer
