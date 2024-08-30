data "azurerm_client_config" "current" {}

data "azurerm_virtual_network" "aks_vnet" {
  count = local.is_custom_dns_private_cluster ? 1 : 0
  name                = reverse(split("/", var.vnet_name))[0]
  resource_group_name = var.vnet_resource_group_name
}

# data "azurerm_resource_group" "aks_rg" {
#   name = var.resource_group_name
# }

# data "azurerm_key_vault" "keyvault" {
#   name                = var.key_vault_name
#   resource_group_name = var.key_vault_resource_group_name
# }