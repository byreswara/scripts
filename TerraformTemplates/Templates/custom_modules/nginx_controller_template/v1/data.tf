data "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.aks_name
  resource_group_name = var.aks_resource_group_name
}

data "azurerm_subscription" "current" {}