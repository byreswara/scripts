resource "azurerm_user_assigned_identity" "aks_umi" {
  name                = "umi-${var.aks_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
}