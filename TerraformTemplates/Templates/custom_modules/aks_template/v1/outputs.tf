# Only works on the very first deployment of the AKS cluster. Should just pull it from azure directly.
# output "key_data" {
#   value = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
# }

output "aks_id" {
  description = "AKS resource id"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_name" {
  description = "Name of the AKS cluster"
  value       = split("/", azurerm_kubernetes_cluster.aks.id)[8]
}

output "aks_nodes_rg" {
  description = "Name of the resource group in which AKS nodes are deployed"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "aks_nodes_pools_ids" {
  description = "Ids of AKS nodes pools"
  value       = azurerm_kubernetes_cluster_node_pool.node_pools[*].id
}

output "aks_nodes_pools_names" {
  description = "Names of AKS nodes pools"
  value       = azurerm_kubernetes_cluster_node_pool.node_pools[*].name
}

output "aks_kube_config_raw" {
  description = "Raw kube config to be used by kubectl command"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "kube_config" {
  description = "Kube configuration of AKS Cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config
  sensitive   = true
}

output "aks_kubelet_user_managed_identity" {
  description = "The Kubelet User Managed Identity used by the AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0]
}

output "key_vault_secrets_provider_identity" {
  description = "The User Managed Identity used by the Key Vault secrets provider."
  value       = try(azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0], null)
}

output "oidc_issuer_url" {
  description = "The URL of the OpenID Connect issuer."
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "grafana_url" {
  value = azurerm_dashboard_grafana.grafana.endpoint
  description = "The URL of the Grafana dashboard"
}

output "grafana_id" {
  description = "grafana resource id"
  value       = azurerm_dashboard_grafana.grafana.id
}
