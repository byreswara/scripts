resource "azurerm_kubernetes_cluster" "res-1" {
  automatic_channel_upgrade = "stable"
  azure_policy_enabled      = true
  dns_prefix                = "aks-qa-01-dns"
  location                  = "centralus"
  name                      = "aks-qa-01"
  resource_group_name       = "rg-qa-aks-01"
  tags = {
    CreationDate = "12/12/2023"
    Deployer     = "Garrett Hazlitt"
    Environment  = "QA"
    location     = "centralus"
  }
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    managed            = true
    tenant_id          = "e19ce0fc-2429-4a9e-b937-3ef24246c22c"
  }
  default_node_pool {
    enable_auto_scaling = true
    max_count           = 5
    min_count           = 2
    name                = "agentpool"
    tags = {
      CreationDate = "12/12/2023"
      Deployer     = "Garrett Hazlitt"
      Environment  = "QA"
      location     = "centralus"
    }
    vm_size        = "Standard_DS2_v2"
    vnet_subnet_id = "/subscriptions/9b28bd6c-83d4-4721-b1e9-cec8810ab5f9/resourceGroups/rg-qa-core-01/providers/Microsoft.Network/virtualNetworks/vnet-qa-central-01/subnets/snet-qa-k8cni-01"
  }
  identity {
    type = "SystemAssigned"
  }
  key_vault_secrets_provider {
  }
  microsoft_defender {
    log_analytics_workspace_id = "/subscriptions/9b28bd6c-83d4-4721-b1e9-cec8810ab5f9/resourcegroups/DefaultResourceGroup-CUS/providers/Microsoft.OperationalInsights/workspaces/DefaultWorkspace-9b28bd6c-83d4-4721-b1e9-cec8810ab5f9-CUS"
  }
  depends_on = [
    azurerm_resource_group.res-0,
  ]
}

resource "azurerm_kubernetes_cluster_node_pool" "res-3" {
  enable_auto_scaling   = true
  kubernetes_cluster_id = "/subscriptions/9b28bd6c-83d4-4721-b1e9-cec8810ab5f9/resourceGroups/rg-qa-aks-01/providers/Microsoft.ContainerService/managedClusters/aks-qa-01"
  max_count             = 3
  min_count             = 2
  name                  = "servicepool"
  tags = {
    CreationDate = "12/12/2023"
    Deployer     = "Garrett Hazlitt"
    Environment  = "QA"
    location     = "centralus"
  }
  vm_size        = "Standard_D2s_v3"
  vnet_subnet_id = "/subscriptions/9b28bd6c-83d4-4721-b1e9-cec8810ab5f9/resourceGroups/rg-qa-core-01/providers/Microsoft.Network/virtualNetworks/vnet-qa-central-01/subnets/snet-qa-k8cni-01"
  zones          = ["1", "3"]
  depends_on = [
    azurerm_kubernetes_cluster.res-1,
  ]
}
resource "azurerm_resource_group" "res-0" {
  location = "centralus"
  name     = "rg-qa-aks-01"
  tags = {
    purpose = "akscluster"
  }
}
resource "azurerm_kubernetes_cluster_node_pool" "res-2" {
  enable_auto_scaling   = true
  kubernetes_cluster_id = "/subscriptions/9b28bd6c-83d4-4721-b1e9-cec8810ab5f9/resourceGroups/rg-qa-aks-01/providers/Microsoft.ContainerService/managedClusters/aks-qa-01"
  max_count             = 5
  min_count             = 2
  mode                  = "System"
  name                  = "agentpool"
  tags = {
    CreationDate = "12/12/2023"
    Deployer     = "Garrett Hazlitt"
    Environment  = "QA"
    location     = "centralus"
  }
  vm_size        = "Standard_DS2_v2"
  vnet_subnet_id = "/subscriptions/9b28bd6c-83d4-4721-b1e9-cec8810ab5f9/resourceGroups/rg-qa-core-01/providers/Microsoft.Network/virtualNetworks/vnet-qa-central-01/subnets/snet-qa-k8cni-01"
  depends_on = [
    azurerm_kubernetes_cluster.res-1,
  ]
}

