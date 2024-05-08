param name string
param k8sNamespace string
param clientId string
param subscriptionId string
param sharedClusterName string
param targetResourceId string

resource managedCluster 'Microsoft.ContainerService/managedClusters@2024-02-01' existing = {
  name: sharedClusterName
}

resource serviceLinker 'Microsoft.ServiceLinker/linkers@2022-11-01-preview' = {
  name: name
  scope: managedCluster
  properties: {
    scope: k8sNamespace
    targetService: {
      type: 'AzureResource'
      id: targetResourceId
    }
    authInfo: {
      authType: 'userAssignedIdentity'
      clientId: clientId
      subscriptionId: subscriptionId
    }
    clientType: 'none'
  }
}
