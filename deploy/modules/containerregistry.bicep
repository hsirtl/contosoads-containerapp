@description('The location of the resources')
param location string = resourceGroup().location

@description('Specifies the common name prefix for all resources.')
@minLength(5)
@maxLength(12)
param baseName string = 'contosoads'

var acrName = '${baseName}${uniqueString(resourceGroup().id)}'
var keyVaultName = '${baseName}${uniqueString(resourceGroup().id)}'
var managedIdentityName = '${baseName}${uniqueString(resourceGroup().id)}'

@description('Provide a tier of your Azure Container Registry.')
param acrSku string = 'Standard'

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource acrResource 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: true
    anonymousPullEnabled: true
  }
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: location
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: guid(resourceGroup().id, acrResource.id, 'acrPullRoleAssignment')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource acrPullLogin 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: keyVault
  name: 'acrPullLogin'
  properties: {
    value: managedIdentity.properties.principalId
  }
}

@description('Output the login server property for later use')
output loginServer string = acrResource.properties.loginServer
