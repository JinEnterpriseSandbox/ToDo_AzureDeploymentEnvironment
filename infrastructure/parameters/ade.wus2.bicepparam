using '../main.bicep'

@description('Base name for the resources')
param baseName = 'adecosmosapp2'

@description('Location for the resources')
param location = 'westus2'

@description('Resource group for Log Analytics')
param logAnalyticsResourceGroup = 'DefaultResourceGroup-EUS2'

@description('Log Analytics workspace name')
param logAnalyticsWorkspace = 'DefaultWorkspace-63862159-43c8-47f7-9f6f-6c63d56b0e17-EUS2'

@description('Resource group for Cosmos DB')
param cosmosDBResourceGroup = 'Shared'

@description('Cosmos DB name')
param cosmosDBName = 'cosmos-nonprod-wus2'
