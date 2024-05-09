# order-service

This sample demonstrates how you can provision Azure resources that support an application in a dev's resource group and deploy the application to a shared AKS cluster with connectivity to the provisioned resources established via AKS Service Connector and Workload Identity.

## Walkthrough

Set deployment variables.

```bash
SHARED_AKS_RESOURCE_GROUP=<YOUR_SHARED_AKS_CLUSTERS_RG_NAME>
SHARED_AKS_CLUSTER_NAME=<YOUR_SHARED_AKS_CLUSTER_NAME>
RAND=$RANDOM
export RAND
DEPLOYMENT_NAME=demo$RAND
LOCATION=<YOUR_PREFERRED_LOCATION>
```

Provision order-service resources in Azure.

```bash
az deployment sub create \
  --location $LOCATION \
  --name $DEPLOYMENT_NAME \
  --template-file ./main.bicep \
  --parameters \
    sharedClusterResourceGroupName=$SHARED_AKS_RESOURCE_GROUP \
    sharedClusterName=$SHARED_AKS_CLUSTER_NAME \
    serviceBusQueueName=orders \
    userObjectId=$(az ad signed-in-user show --query id -o tsv)
```

Load outputs into environment variables.

```bash
export SERVICE_BUS_HOSTNAME=$(az deployment sub show --name $DEPLOYMENT_NAME --query properties.outputs.serviceBusHostName.value -o tsv)
export SERVICE_BUS_QUEUE_NAME=$(az deployment sub show --name $DEPLOYMENT_NAME --query properties.outputs.serviceBusQueueName.value -o tsv)
export SERVICE_ACCOUNT_NAME=$(az deployment sub show --name $DEPLOYMENT_NAME --query properties.outputs.serviceAccountName.value -o tsv)
```

Swap out placeholders in the kustomization.yaml template file.

```bash
envsubst < ./manifests/kustomization.yaml.tmpl > ./manifests/kustomization.yaml
```

Connect to the shared cluster.

```bash
az aks get-credentials --resource-group $SHARED_AKS_RESOURCE_GROUP --name $SHARED_AKS_CLUSTER_NAME
```

Deploy the order-service to the shared cluster.

```bash
kubectl apply -k ./manifests --namespace $DEPLOYMENT_NAME
```

Get the cluster IP of the order-service.

```bash
CLUSTER_IP=$(kubectl get svc order-service --namespace $DEPLOYMENT_NAME -o jsonpath="{.spec.clusterIPs[0]}")
```

Test the order-service by submitting a POST request from a Pod in the cluster.

```bash
kubectl run -it --rm --restart=Never curl --image=curlimages/curl -- curl -X POST http://$CLUSTER_IP:3000/ -H "accept: application/json" -H "Content-Type: application/json" -d "{\"customerId\": \"1234567890\",\"items\": [{\"productId\": 1,\"quantity\": 1,\"price\": 10},{\"productId\": 2,\"quantity\": 2,\"price\": 20}]}"
```

> [!NOTE] If you see an error message, it may be because the order-service is not yet ready. Wait a few seconds and try again.

In Azure Portal, navigate to the Azure Service Bus resource and use Azure Service Bus Explorer to view the order message in the queue.

Clean up deployment and resources.

```bash
az deployment sub delete -n $DEPLOYMENT_NAME --no-wait
az group delete -n rg-$DEPLOYMENT_NAME -y --no-wait
```
