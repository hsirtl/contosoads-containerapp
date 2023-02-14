@description('Specifies the location to deploy to.')
param location string = resourceGroup().location

@description('Specifies the common name prefix for all resources.')
@minLength(5)
@maxLength(12)
param baseName string = 'contosoads'

//@description('Specifies the name of the blob container.')
//param containerName string = 'images'

//@description('Specifies the name of the request queue.')
//param requestQueueName string = 'thumbnail-request'

//@description('Specifies the name of the result queue.')
//param resultQueueName string = 'thumbnail-result'

@description('Specifies the PostgreSQL version.')
param postgresVersion string = '14'

@description('Specifies the tag for the contosoads-web image.')
param webAppTag string = 'latest'

@description('Specifies the tag for the contosoads-api image.')
param webApiTag string = 'latest'

@description('Specifies the tag for the contosoads-imageprocessor image.')
param imageProcessorTag string = 'latest'

@description('Specifies the public Git repo that hosts the database migration script.')
param repository string

var vnetName = '${baseName}-vnet'
var keyVaultName = '${baseName}${uniqueString(resourceGroup().id)}'
var acrName = '${baseName}${uniqueString(resourceGroup().id)}'
//var storageAccountName = '${baseName}${uniqueString(resourceGroup().id)}'
var privateDnsZoneName = '${baseName}.postgres.database.azure.com'
var postgresHostName = 'server${uniqueString(resourceGroup().id)}'
var databaseName = 'contosoads'

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

module network 'modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
    vnetName: vnetName
    privateDnsZoneName: privateDnsZoneName
  }
}

resource environment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: '${baseName}-env'
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: '${baseName}-insights'
}

/*
module environment 'modules/environment.bicep' = {
  name: 'environment'
  params: {
    location: location
    baseName: baseName
    infrastructureSubnetId: network.outputs.infraSubnetId
    storageAccountName: storageAccountName
    containerName: containerName
    requestQueueName: requestQueueName
    resultQueueName: resultQueueName
  }
}
*/

module postgres 'modules/database.bicep' = {
  name: 'postgres'
  params: {
    location: location
    serverName: postgresHostName
    databaseName: databaseName
    postgresSubnetId: network.outputs.pgSubnetId
    aciSubnetId: network.outputs.aciSubnetId
    privateDnsZoneId: network.outputs.privateDnsZoneId
    administratorLogin: keyVault.getSecret('postgresLogin')
    administratorLoginPassword: keyVault.getSecret('postgresLoginPassword')
    version: postgresVersion
    repository: repository
  }
}

module webapp 'modules/webapp.bicep' = {
  name: 'webapp'
  params: {
    location: location
    registryName: acrName
    registryLogin: keyVault.getSecret('acrPullLogin')
    tag: webAppTag
    environmentId: environment.id
    postgresHostName: postgresHostName
    databaseName: databaseName
    postgresLogin: keyVault.getSecret('postgresLogin')
    postgresLoginPassword: keyVault.getSecret('postgresLoginPassword')
    aiConnectionString: appInsights.properties.ConnectionString
  }
  dependsOn: [ postgres ]
}

module webapi 'modules/webapi.bicep' = {
  name: 'webapi'
  params: {
    location: location
    registryName: acrName
    registryLogin: keyVault.getSecret('acrPullLogin')
    tag: webApiTag
    environmentId: environment.id
    postgresHostName: postgresHostName
    databaseName: databaseName
    postgresLogin: keyVault.getSecret('postgresLogin')
    postgresLoginPassword: keyVault.getSecret('postgresLoginPassword')
    aiConnectionString: appInsights.properties.ConnectionString
  }
  dependsOn: [ postgres ]
}

module imageprocessor 'modules/imageprocessor.bicep' = {
  name: 'imageprocessor'
  params: {
    location: location
    registryName: acrName
    registryLogin: keyVault.getSecret('acrPullLogin')
    tag: imageProcessorTag
    environmentId: environment.id
    aiConnectionString: appInsights.properties.ConnectionString
  }
  dependsOn: [ postgres ]
}

output fqdn string = webapp.outputs.fqdn
