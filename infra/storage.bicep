@description('Storage Account type')
@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_LRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Standard_ZRS'
])

param storageAccountType string = 'Standard_LRS'

// @description('The name of the resource group.')
// param resourceGroupName string

// @description('The location for the resource group.')
// param resourceGroupLocation string

@description('The storage account location.')
param storageAccountLocation string = resourceGroup().location

@description('The name of the storage account')
param storageAccountName string = 'e${uniqueString(resourceGroup().id)}stg'


resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: storageAccountLocation
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {
    defaultToOAuthAuthentication: false
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource sa_blob 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: sa
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: false
    }
  }
}

resource sa_file 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = {
  parent: sa
  name: 'default'
  properties: {
    protocolSettings: {
      smb: {}
    }
    cors: {
      corsRules: []
    }
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource sa_queue 'Microsoft.Storage/storageAccounts/queueServices@2023-05-01' = {
  parent: sa
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource sa_table 'Microsoft.Storage/storageAccounts/tableServices@2023-05-01' = {
  parent: sa
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource sa_web_blob 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: sa_blob
  name: '$web'
  properties: {
    immutableStorageWithVersioning: {
      enabled: false
    }
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
}

output resourceGroupName string = resourceGroup().name
output resourceGroupLocation string = resourceGroup().location
output storageAccountName string = sa.name
output storageAccountLocation string = sa.location
