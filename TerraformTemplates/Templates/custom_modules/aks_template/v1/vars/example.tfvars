# naming convention
aks_name     = "anothertest"

# tag vars
default_tags_enabled   = true
extra_tags             = {}
default_node_pool_tags = {}

# keyvault vars
key_vault_name                = "TCkeyvault-qa1"
key_vault_resource_group_name = "keyvault-qa-rg"
key_vault_secrets_provider    = null

# default vars

location                              = "centralus"
resource_group_name                   = "rg-terratesting-qa"
kubernetes_version                    = "1.27.9"
identity_type                         = "UserAssigned" # can be UserAssigned or SystemAssigned
node_resource_group                   = null             # may want to define this 
private_cluster_enabled               = true
role_based_access_control_enabled     = true
aks_role_based_access_control_enabled = true # Validate the purpose of azure_active_directory_role_based_access_control vs role_based_access_control_enabled
vnet_id                               = "146877ae-bb87-473f-bdb7-56db1c854723"
vnet_name                             = "vnet-qa-central-01"
private_dns_zone_type = "Custom"
# private_dns_zone_id     = null   
aks_sku_tier            = "Free"
aks_network_plugin      = "azure"
aks_network_policy      = "" # can be azure or calico
aks_http_proxy_settings = null
default_node_pool = {
  "name"       = "systempool"
  "node_count" = 1
  "vm_size"    = "Standard_DS2_v2"
  "os_type"    = "Linux"
  "zones" = [
    1,
    3,
  ]
  "enable_auto_scaling"    = true
  "min_count"              = 1
  "max_count"              = 2
  "type"                   = "VirtualMachineScaleSets"
  "node_taints"            = null
  "node_labels"            = null
  "orchestrator_version"   = null
  "priority"               = null
  "enable_host_encryption" = null
  "eviction_policy"        = null
  "max_pods"               = 30
  "os_disk_type"           = "Managed"
  "os_disk_size_gb"        = 128
  "enable_node_public_ip"  = false
}
nodes_subnet_id      = "/subscriptions/9b28bd6c-83d4-4721-b1e9-cec8810ab5f9/resourceGroups/rg-qa-core-01/providers/Microsoft.Network/virtualNetworks/vnet-qa-central-01/subnets/snet-qa-k8cni-01"
auto_scaler_profile  = null
azure_policy_enabled = true
service_cidr         = "10.2.0.0/16"
aks_pod_cidr         = "127.17.0.0/16" #"CIDR used by pods when network plugin is set to `kubenet`. https://docs.microsoft.com/en-us/azure/aks/configure-kubenet"
outbound_type        = "loadBalancer"
docker_bridge_cidr   = "172.17.0.1/16" #"IP address for docker with Network CIDR."
nodes_pools = [
  {
    "name"       = "servicepool"
    "node_count" = 2
    "vm_size"    = "Standard_DS2_v2"
    "os_type"    = "Linux"
    "zones" = [
      1,
      3,
    ]
    "enable_auto_scaling"    = true
    "min_count"              = 2
    "max_count"              = 5
    "type"                   = "VirtualMachineScaleSets"
    "node_taints"            = null
    "node_labels"            = {nodepool="service"}
    "orchestrator_version"   = null
    "priority"               = null
    "enable_host_encryption" = null
    "eviction_policy"        = null
    "max_pods"               = 50
    "os_disk_type"           = "Managed"
    "os_disk_size_gb"        = 128
    "enable_node_public_ip"  = false
    "mode"                   = "System"
  }
]

# roles-access vars
aks_private_dns_zone_id    = ""  # get this value from private_dns_zone module
aks_subnet_id              = ""  # get this value using data block 

log_analytics_workspace_name      = "DefaultWorkspace-9b28bd6c-83d4-4721-b1e9-cec8810ab5f9-CUS"
log_analytics_resource_group_name = "defaultresourcegroup-cus"

