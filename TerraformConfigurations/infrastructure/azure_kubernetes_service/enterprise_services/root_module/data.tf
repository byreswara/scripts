data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "aks_rg" {
  name = var.resource_group_name
}
data "azurerm_virtual_network" "aks_vnet" {
  name                 = var.vnet_name
  resource_group_name  = var.vnet_resource_group_name
}

data "azurerm_private_dns_zone" "aks_dns_zone" {
  name = "privatelink.centralus.azmk8s.io"
  provider = azurerm.Identity
}

data "azurerm_container_registry" "aks_acr" {
  name     = var.acr_name
  resource_group_name = var.acr_resource_group_name
}

data "azurerm_key_vault" "keyvault" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group_name
}

data "azurerm_log_analytics_workspace" "law" {
  name                = var.log_analytics_workspace_name
  resource_group_name = var.log_analytics_resource_group_name
}