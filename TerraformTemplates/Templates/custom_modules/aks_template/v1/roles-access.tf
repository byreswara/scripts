# deployment account needs to have Role Based Access Control Administrator for all of these:

resource "azurerm_role_assignment" "aks_acr_pull_allowed" {
  for_each = toset(var.container_registries_id)

  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  scope                = each.value
  role_definition_name = "AcrPull"
}

resource "azurerm_role_assignment" "aks_snet_network_contributor" {
  principal_id         = azurerm_user_assigned_identity.aks_umi.principal_id
  scope                = var.aks_subnet_id
  role_definition_name = "Network Contributor"
}

resource "azurerm_role_assignment" "umi_dns_zone_contributor" {
  principal_id         = azurerm_user_assigned_identity.aks_umi.principal_id
  scope                = var.aks_private_dns_zone_id
  role_definition_name = "Private DNS Zone Contributor"
}

# # resource "azurerm_role_assignment" "aks_user_assigned" {
# #   principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
# #   scope                = format("/subscriptions/%s/resourceGroups/%s", data.azurerm_client_config.current.subscription_id, azurerm_kubernetes_cluster.aks.node_resource_group)
# #   role_definition_name = "Contributor"
# # }

resource "azurerm_key_vault_access_policy" "aks_access_to_kv" {
  depends_on       = [azurerm_kubernetes_cluster.aks]
  key_vault_id     = var.keyvault_id                                                  # data.azurerm_key_vault.keyvault.id
  tenant_id        = data.azurerm_client_config.current.tenant_id
  object_id        = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].object_id

  certificate_permissions = [
    "Get",
  ]

  secret_permissions = [
    "Get",
  ]

  key_permissions = [
    "Get",
  ]
    
}
resource "azurerm_role_assignment" "grafana" {
  scope                = var.resource_group_id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.grafana.identity[0].principal_id
}

