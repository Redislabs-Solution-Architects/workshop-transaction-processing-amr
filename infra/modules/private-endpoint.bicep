// Generic Private Endpoint module
// Creates a private endpoint and links it to a private DNS zone

@description('Name of the private endpoint')
param name string

@description('Azure region for the resource')
param location string

@description('Resource ID of the subnet for the private endpoint')
param subnetId string

@description('Resource ID of the target service')
param privateLinkServiceId string

@description('Group IDs for the private link (e.g., redisEnterprise, registry)')
param groupIds array

@description('Resource ID of the private DNS zone')
param privateDnsZoneId string

@description('Tags to apply to resources')
param tags object = {}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${name}-connection'
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

output id string = privateEndpoint.id
output name string = privateEndpoint.name
