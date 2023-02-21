@description('The location of the resources')
param location string = resourceGroup().location

@description('Specifies the common name prefix for all resources.')
@minLength(5)
@maxLength(12)
param baseName string = 'contosoads'

var acrName = '${baseName}${uniqueString(resourceGroup().id)}'
var keyVaultName = '${baseName}${uniqueString(resourceGroup().id)}'
var managedIdentityName = '${baseName}${uniqueString(resourceGroup().id)}'

var acrPullRole = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

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

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: managedIdentityName
  location: location
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, acrResource.id, 'acrPullRoleAssignment')
  properties: {
    roleDefinitionId: acrPullRole
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource acrPullLogin 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: keyVault
  name: 'acrPullLogin'
  properties: {
    value: managedIdentity.id
  }
}

@description('Output the login server property for later use')
output loginServer string = acrResource.properties.loginServer

@description('Output the resource ID for later use')
output acrName string = acrResource.name
