param location string = deployment().location
param sharedClusterName string
param sharedClusterResourceGroupName string
param serviceBusQueueName string
@secure()
param userObjectId string

targetScope = 'subscription'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  location: location
  name: 'rg-${deployment().name}'
}

module serviceBus 'modules/serviceBus.bicep' = {
  name: '${sharedClusterName}-servicebus'
  scope: resourceGroup
  params: {
    location: resourceGroup.location
    prefix: 'sb-${deployment().name}'
    queueName: serviceBusQueueName
    userObjectId: userObjectId
  }
}

resource sharedClusterResourceGroup 'Microsoft.Resources/resourceGroups@2020-06-01' existing = {
  name: sharedClusterResourceGroupName
}

module serviceBusConnection 'modules/serviceConnector.bicep' = {
  name: deployment().name
  scope: sharedClusterResourceGroup
  params: {
    name: deployment().name
    clientId: serviceBus.outputs.clientId
    subscriptionId: subscription().subscriptionId
    targetResourceId: serviceBus.outputs.id
    sharedClusterName: sharedClusterName
    k8sNamespace: deployment().name
  }
}

output serviceBusHostName string = serviceBus.outputs.hostName
output serviceBusQueueName string = serviceBus.outputs.queueName
output serviceAccountName string = serviceBus.outputs.serviceAccountName
