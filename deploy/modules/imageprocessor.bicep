@description('Specifies the registry of the ContosoAds web application container.')
param registryName string

@description('Specifies the managed identity to be used for accessing the registry.')
@secure()
param registryLogin string

@description('Specifies the tag of the ContosoAds image processor container.')
param tag string

@description('Specifies the location to deploy to.')
param location string 

@description('Specifies the name of Azure Container Apps environment to deploy to.')
param environmentId string

@description('Specifies the Application Insights connection string.')
param aiConnectionString string

var secrets = [
  {
    name: 'ai-connection-string'
    value: aiConnectionString
  }
]

var containerPort = 8081

resource imageProcessor 'Microsoft.App/containerApps@2022-10-01' = {
  name: 'contosoads-imageprocessor'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${registryLogin}': {}
    }
  }
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      secrets: secrets
      registries: [
        {
          identity: registryLogin
          server: '${registryName}.azurecr.io'
        }
      ]
      dapr: {
        enabled: true
        appId: 'contosoads-imageprocessor'
        appPort: containerPort
      }

    }
    template: {
      containers: [
        {
          image: '${registryName}.azurecr.io/contosoads-imageprocessor:${tag}'
          name: 'contosoads-imageprocessor'
          env: [
            {
              name: 'ApplicationInsights__ConnectionString'
              secretRef: 'ai-connection-string'
            }           
            {
              name: 'Logging__ApplicationInsights__LogLevel__ContosoAds'
              value: 'Debug'
            }           
          ]
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
      }
    }
  }
}

