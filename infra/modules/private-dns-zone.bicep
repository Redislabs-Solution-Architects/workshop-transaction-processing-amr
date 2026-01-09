// Private DNS Zone for Azure Private Endpoints
// Links the DNS zone to the VNet for private endpoint resolution

@description('Name of the private DNS zone (e.g., privatelink.redis.cache.windows.net)')
param name string

@description('Resource ID of the VNet to link')
param vnetId string

@description('Tags to apply to resources')
param tags object = {}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: name
  location: 'global'
  tags: tags
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${replace(name, '.', '-')}-link'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

output id string = privateDnsZone.id
output name string = privateDnsZone.name
