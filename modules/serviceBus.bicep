param prefix string
param queueName string
param location string
param userObjectId string

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: '${prefix}${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    disableLocalAuth: true
  }
}

resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = {
  name: queueName
  parent: serviceBusNamespace
}

resource serviceBusIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${serviceBusNamespace.name}-id'
  location: location
}

// https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/integration#azure-service-bus-data-owner
var roleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '090c5cfd-751d-490a-894a-3ce6f1109419')
resource serviceBusRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, 'roleAssignment', 'serviceBusNamespace', serviceBusNamespace.name, serviceBusIdentity.name)
  scope: serviceBusNamespace
  properties: {
    principalId: userObjectId
    principalType: 'User'
    roleDefinitionId: roleDefinitionId
  }
}

output id string = serviceBusNamespace.id
output namespace string = serviceBusNamespace.name
output hostName string = replace(replace(serviceBusNamespace.properties.serviceBusEndpoint, 'https://', ''), ':443/', '')
output queueName string = serviceBusQueue.name
output clientId string = serviceBusIdentity.properties.clientId
output serviceAccountName string = 'sc-account-${serviceBusIdentity.properties.clientId}'
