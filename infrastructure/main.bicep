@description('Location for all resources.')
param location string
@description('Base name that will appear for all resources.') 
param baseName string = 'adecosmosapp2'
@description('Three letter environment abreviation to denote environment that will appear in all resource names') 
param environmentName string = 'cicd'
@description('App Service Plan Sku') 
param appServicePlanSKU string = 'D1'
@description('Resource Group Log Analytics Workspace is in')
param logAnalyticsResourceGroup string 
@description('Log Analytics Workspace Name')
param logAnalyticsWorkspace string
@description('Resource Group CosmosDB is in')
param cosmosDBResourceGroup string
@description('CosmosDB Name')
param cosmosDBName string
@description('Dev Center Project Name')
param devCenterProjectName string = ''
@description('Name for the Azure Deployment Environment')
param adeName string =  ''


var regionReference = {
  centralus: 'cus'
  eastus: 'eus'
  westus: 'wus'
  westus2: 'wus2'
}

// var language = 'Bicep'

//targetScope = 'subscription'
var nameSuffix = empty(adeName) ?  toLower('${baseName}-${environmentName}-${regionReference[location]}') : '${devCenterProjectName}-${adeName}'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspace
  scope: resourceGroup(logAnalyticsResourceGroup)
}

resource cosmosDB 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' existing ={
  name: cosmosDBName
  scope: resourceGroup(cosmosDBResourceGroup)
}
module userAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: 'userAssignedIdentityDeployment'
  params: {
    name: nameSuffix
    location: location
  }
}

module appServicePlan 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: 'appServicePlanModule'
  params:{
    location: location
    name: nameSuffix
    skuName: appServicePlanSKU
    kind: 'app'
  }
}

module appService 'br/public:avm/res/web/site:0.13.1' ={
  name: 'appServiceModule'
  params:{
    location: location
    
    serverFarmResourceId: appServicePlan.outputs.resourceId
    kind: 'app,container,windows'
    name: nameSuffix
    managedIdentities: {
      systemAssigned: true
      userAssignedResourceIds: [
        userAssignedIdentity.outputs.resourceId
      ]
    }
    siteConfig: {
      alwaysOn: false
    }
    appInsightResourceId: appInsights.outputs.applicationInsightsResourceId

    appSettingsKeyValuePairs: {
      CosmosDb__Account: 'https://${cosmosDB.name}.documents.azure.com:443/'
      CosmosDb__DatabaseName: 'Tasks'
      CosmosDb__ContainerName: 'Item'
      WEBSITE_RUN_FROM_PACKAGE: '1'
      SCM_DO_BUILD_DURING_DEPLOYMENT: 'true'
      ApplicationInsightsAgent_EXTENSION_VERSION: '~2'
    }
  }
}

module appInsights 'br/public:avm/ptn/azd/insights-dashboard:0.1.0' = {
  name: 'applicationinsights'
  params: {
    logAnalyticsWorkspaceResourceId: logAnalytics.id
    name: nameSuffix
    location: location
    dashboardName: 'Favorites'
    enableTelemetry: true
  }
}

module cosmosRBAC './module/cosmossqldbroleassignment/main.bicep' ={
  name: 'cosmosRBACModule'
  scope: resourceGroup(cosmosDBResourceGroup)
  params: {
    databaseAccountName: cosmosDB.name
    databaseAccountResourceGroup: cosmosDBResourceGroup
    principalId: appService.outputs.systemAssignedMIPrincipalId
  }
}




