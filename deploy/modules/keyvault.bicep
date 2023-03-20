@description('The location of the resources')
param location string = resourceGroup().location

@description('Specifies the common name prefix for all resources.')
@minLength(5)
@maxLength(12)
param baseName string = 'contosoads'

var keyVaultName = '${baseName}${uniqueString(resourceGroup().id)}'

@description('The SKU of the vault to be created.')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@secure()
@description('The administrator login username for the Contoso Ads DB server.')
param postgresLogin string

@secure()
@description('The administrator login password for the Contoso Ads DB server.')
param postgresLoginPassword string

resource vault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    accessPolicies:[]
    enableRbacAuthorization: false
    enableSoftDelete: false
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    tenantId: subscription().tenantId
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource sqlLogin 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: vault
  name: 'postgresLogin'
  properties: {
    value: postgresLogin
  }
}

resource sqlPassword 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: vault
  name: 'postgresLoginPassword'
  properties: {
    value: postgresLoginPassword
  }
}

output keyVaultId string = vault.id
output keyVaultName string = vault.name
