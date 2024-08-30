# Cluster Authentication is configured through Azure Resource Manager connection setting in this task.
param(
    [string]$aks_resource_group,
    [string]$aks_cluster_name,
    [string]$namespace
)
write-host '========================================'`n
write-host 'Authenticating to AKS'`n
write-host 'Resource Group:' $aks_resource_group
write-host 'Cluster Name:' $aks_cluster_name
az aks get-credentials --resource-group $aks_resource_group --name $aks_cluster_name --overwrite-existing
kubelogin convert-kubeconfig -l azurecli

write-host '========================================'`n
write-host 'Creating Namespace if it does not exist'`n
kubectl create namespace $namespace --dry-run=client -o yaml | kubectl apply -f -

write-host '========================================'`n
$kv_provider_id = (az aks show -g $aks_resource_group -n $aks_cluster_name --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)
write-host "AKS KeyVault Provider Identity ID: $kv_provider_id"
write-host "##vso[task.setvariable variable=kv_provider_id]$kv_provider_id"

write-host '========================================'`n


