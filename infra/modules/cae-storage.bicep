// Module to create storage link in Container Apps Environment
// This ensures the storage is created ONCE before any apps try to use it

param envName string
param storageAccountName string
@secure()
param storageAccountKey string
param shareName string

resource containerAppsEnv 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: envName
}

resource storageLink 'Microsoft.App/managedEnvironments/storages@2024-03-01' = {
  parent: containerAppsEnv
  name: 'modules-storage'
  properties: {
    azureFile: {
      accountName: storageAccountName
      accountKey: storageAccountKey
      shareName: shareName
      accessMode: 'ReadWrite'
    }
  }
}

output storageName string = storageLink.name
