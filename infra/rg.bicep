targetScope='subscription'

@description('The name of the resource group.')
param resourceGroupName string

@description('The location for the resource group.')
param resourceGroupLocation string

resource newRG 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: resourceGroupLocation
}

module storageAcct 'storage.bicep' = {
  name: 'storageModule'
  scope: newRG
  // params: {
  //   // resourceGroupName: resourceGroupName
  //   // resourceGroupLocation: resourceGroupLocation
  // }
}

output resourceGroupName string = newRG.name
output resourceGroupLocation string = newRG.location
output storageAccountName string = storageAcct.outputs.storageAccountName
output storageAccountLocation string = storageAcct.outputs.storageAccountLocation
