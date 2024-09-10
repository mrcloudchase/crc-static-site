@description('The name of the function app that you wish to create.')
param appName string = 'fnapp${uniqueString(resourceGroup().id)}'

@description('Storage Account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param storageAccountType string = 'Standard_LRS'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Location for Application Insights')
param appInsightsLocation string = resourceGroup().location

@description('Name of the Cosmos DB account')
param cosmosDbAccountName string = 'cosmosdb${uniqueString(resourceGroup().id)}'

@description('Name of the Cosmos DB database')
param cosmosDbDatabaseName string = 'PageViewsDB'

@description('Name of the Cosmos DB container')
param cosmosDbContainerName string = 'Counters'

@description('Partition key for the Cosmos DB container')
param cosmosDbPartitionKey string = '/id'

var functionAppName = appName
var hostingPlanName = appName
var applicationInsightsName = appName
var storageAccountName = '${uniqueString(resourceGroup().id)}azfunctions'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
  }
}

// Create an App Service Plan for the Function App (Consumption Plan)
resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'  // Consumption Plan
    tier: 'Dynamic'
  }
  properties: {}
}

// Create the Function App with a System-Assigned Managed Identity
resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'  // Managed identity for accessing Cosmos DB
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'  // Python runtime
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'COSMOS_DB_URI'
          value: cosmosDbAccount.properties.documentEndpoint  // Cosmos DB URI
        }
        {
          name: 'COSMOS_DB_DATABASE_NAME'
          value: cosmosDbDatabaseName  // Cosmos DB database name
        }
        {
          name: 'COSMOS_DB_CONTAINER_NAME'
          value: cosmosDbContainerName  // Cosmos DB container name
        }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

// Create Cosmos DB Account
resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-04-15' = {
  name: cosmosDbAccountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
    databaseAccountOfferType: 'Standard'
  }
}

// Create Cosmos DB Database
resource cosmosDbDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-04-15' = {
  name: '${cosmosDbAccountName}/${cosmosDbDatabaseName}'
  properties: {
    resource: {
      id: cosmosDbDatabaseName
    }
  }
  dependsOn: [
    cosmosDbAccount
  ]
}

// Create Cosmos DB Container
resource cosmosDbContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-04-15' = {
  name: '${cosmosDbAccountName}/${cosmosDbDatabaseName}/${cosmosDbContainerName}'
  properties: {
    resource: {
      id: cosmosDbContainerName
      partitionKey: {
        paths: [
          cosmosDbPartitionKey
        ]
        kind: 'Hash'
      }
    }
  }
  dependsOn: [
    cosmosDbDatabase
  ]
}

// Create Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: appInsightsLocation
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

// Role Assignment for Managed Identity to Access Cosmos DB
resource cosmosDbRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, functionApp.identity.principalId, 'b24988ac-6180-42a0-ab88-20f7382dd24c')  // Role assignment ID
  scope: cosmosDbAccount.id
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'  // Cosmos DB Built-in Data Contributor
    principalId: functionApp.identity.principalId
  }
}

output functionAppName string = functionApp.name
output cosmosDbAccountName string = cosmosDbAccount.name
