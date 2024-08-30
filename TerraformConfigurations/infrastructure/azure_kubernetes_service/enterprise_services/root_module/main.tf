# AKS Modules:
module "aks" {
  source                                = "./modules/aks_template/v1"
  aks_http_proxy_settings               = var.aks_http_proxy_settings
  aks_name                              = var.aks_name
  aks_network_plugin                    = var.aks_network_plugin
  aks_network_policy                    = var.aks_network_policy
  aks_pod_cidr                          = var.aks_pod_cidr
  aks_role_based_access_control_enabled = var.aks_role_based_access_control_enabled
  aks_sku_tier                          = var.aks_sku_tier
  automatic_channel_upgrade             = var.automatic_channel_upgrade
  auto_scaler_profile                   = var.auto_scaler_profile
  azure_policy_enabled                  = var.azure_policy_enabled
  container_registries_id               = [data.azurerm_container_registry.aks_acr.id]
  default_node_pool                     = var.default_node_pool
  docker_bridge_cidr                    = var.docker_bridge_cidr
  identity_type                         = var.identity_type
  key_vault_name                        = var.key_vault_name
  key_vault_resource_group_name         = var.key_vault_resource_group_name
  key_vault_secrets_provider            = var.key_vault_secrets_provider
  kubernetes_version                    = var.kubernetes_version
  location                              = var.location
  node_resource_group                   = var.node_resource_group
  nodes_subnet_id                       = module.azure_subnet.subnet_id # module.azure_subnet.subnet_id                   # data.azurerm_subnet.aks_subnet.id
  aks_subnet_id                         = module.azure_subnet.subnet_id # module.azure_subnet.subnet_id                  #data.azurerm_subnet.aks_subnet.id
  nodes_pools                           = var.nodes_pools
  outbound_type                         = var.outbound_type
  private_cluster_enabled               = var.private_cluster_enabled
  aks_private_dns_zone_id               = data.azurerm_private_dns_zone.aks_dns_zone.id # data.azurerm_private_dns_zone.aks_dns_zone.id    # module.aks-private-dns-zone.id
  resource_group_name                   = var.resource_group_name
  resource_group_id                     = data.azurerm_resource_group.aks_rg.id
  role_based_access_control_enabled     = var.role_based_access_control_enabled
  service_cidr                          = var.service_cidr
  vnet_id                               = data.azurerm_virtual_network.aks_vnet.id
  vnet_name                             = var.vnet_name
  deployer                              = var.deployer
  ado_Project                           = var.ado_Project
  ado_Repository                        = var.ado_Repository
  ado_Branch                            = var.ado_Branch
  private_dns_zone_type                 = var.private_dns_zone_type
  extra_tags                            = var.extra_tags
  vnet_resource_group_name              = var.vnet_resource_group_name
  keyvault_id                           = data.azurerm_key_vault.keyvault.id
  log_analytics_workspace_id            = data.azurerm_log_analytics_workspace.law.id
  iam_policies                          = var.grafana_iam_policies
  network_plugin_mode                   = var.network_plugin_mode
 }

module "aks-rbac" {
  source       = "./modules/iam_template/v1"
  iam_policies = var.iam_policies
  iam_scope    = module.aks.aks_id
}

module "aks-identity-rbac" {
  source = "./modules/iam_template/v1"
  iam_policies = [{
    object_id = data.azurerm_client_config.current.object_id,
    role      = "Azure Kubernetes Service RBAC Cluster Admin"
  }]
  iam_scope = module.aks.aks_id
}
module "azure_network_security_group" {
  source = "./modules/nsg_template/v1"

  nsg_name            = var.nsg_name
  location            = var.location
  resource_group_name = var.nsg_resource_group_name
  additional_rules = var.additional_rules
  deployer         = var.deployer
  ado_Project      = var.ado_Project
  ado_Repository   = var.ado_Repository
  ado_Branch       = var.ado_Branch
}

module "azure_subnet" {
  source = "./modules/snet_template/v1"
  virtual_network_name = data.azurerm_virtual_network.aks_vnet.name
  resource_group_name  = var.vnet_resource_group_name
  subnet_name          = var.subnet_name
  subnet_cidr_list     = var.subnet_cidr_list
  network_security_group_id = module.azure_network_security_group.network_security_group_id
  service_endpoints         = var.service_endpoints
  service_endpoint_policy_ids = var.service_endpoint_policy_ids
  subnet_delegation           = var.subnet_delegation
  private_link_endpoint_enabled = var.private_link_endpoint_enabled
  network_security_group_name = module.azure_network_security_group.network_security_group_name
  route_table_name = var.route_table_name
  route_table_id = var.route_table_id
  location_short = var.location_short
  environment = var.environment
}

module "grafana-rbac" {
  source       = "./modules/iam_template/v1"
  iam_policies = var.grafana_iam_policies
  iam_scope    = module.aks.grafana_id
}