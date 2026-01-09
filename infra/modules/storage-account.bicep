// Azure Storage Account with File Share for workshop modules

@description('Name of the storage account')
param name string

@description('Azure region for the resource')
param location string

@description('Tags to apply to resources')
param tags object = {}

@description('Name of the file share')
param shareName string = 'modules'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Allow' // Allow access from Container Apps
      bypass: 'AzureServices'
    }
  }
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  parent: fileService
  name: shareName
  properties: {
    shareQuota: 1 // 1 GB is plenty for Python modules
  }
}

output id string = storageAccount.id
output name string = storageAccount.name
output shareName string = fileShare.name
output primaryEndpoint string = storageAccount.properties.primaryEndpoints.file
#disable-next-line outputs-should-not-contain-secrets
output accessKey string = storageAccount.listKeys().keys[0].value
