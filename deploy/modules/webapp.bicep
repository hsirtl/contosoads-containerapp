@description('Specifies the registry of the ContosoAds web application container.')
param registryName string

@description('Specifies the tag of the ContosoAds web application container.')
param tag string

@description('Specifies the location to deploy to.')
param location string 

@description('Specifies the name of Azure Container Apps environment to deploy to.')
param environmentId string

@description('Specifies the name of the Azure Database for PostgreSQL server.')
param postgresHostName string

@description('Specifies the name of the Azure Database for PostgreSQL database.')
param databaseName string

@description('Specifies the login name of the Azure Database for PostgreSQL server.')
@secure()
param postgresLogin string

@description('Specifies the login password of the Azure Database for PostgreSQL server.')
@secure()
param postgresLoginPassword string

@description('Specifies the Application Insights connection string.')
param aiConnectionString string

var dbConnectionString = 'Host=${postgresHostName}.postgres.database.azure.com;Database=${databaseName};Username=${postgresLogin};Password=${postgresLoginPassword}'

var secrets = [
  {
    name: 'db-connection-string'
    value: dbConnectionString
  }
  {
    name: 'ai-connection-string'
    value: aiConnectionString
  }
]

var containerPort = 8080

resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: 'contosoads-web'
  location: location
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      secrets: secrets
      ingress: {
        external: true
        targetPort: containerPort
      }
      dapr: {
        appId: 'contosoads-web'
        appPort: containerPort
        enabled: true
      }
    }
    template: {
      containers: [
        {
          image: '${registryName}/contosoads-web:${tag}'
          name: 'contosoads-webapp'
          env: [
            {
              name: 'ConnectionStrings__DefaultConnection'
              secretRef: 'db-connection-string'
            }
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
          rules: [
            {
              name: 'httpscale'
              http: {
                metadata: {
                  concurrentRequests: '100'
                }
            }
          }
        ]
      }
    }
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
