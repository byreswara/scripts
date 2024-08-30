# rbac variables:
iam_policies = [
  {
    # group: sg.azure.k8.admin
    object_id = "a180a7cf-100c-4e4a-8a8f-9f8ba96163d5"
    role      = "Azure Kubernetes Service RBAC Cluster Admin"
  }
]

# tag variables:
default_tags_enabled   = true
extra_tags             = {}
default_node_pool_tags = {}

# subnets data source variables:
aks_subnet_name          = "snet-prod-k8cni-01"
vnet_name                = "vnet-prod-central-01"
vnet_resource_group_name = "rg-prod-core-01"

# keyvault data source variables:
key_vault_name                = "keyvault-prod-cus-es-01"
key_vault_resource_group_name = "rg-keyvault-prod"

# acr data source variables:
acr_name                = "mercalisprod"
acr_resource_group_name = "rg-acr-prod"

# aks name variables:
aks_name            = "aks-prod-cus-es-01"
resource_group_name = "rg-aks-prod-cus-es-01"
ssh_key_name        = "ssh-aks-prod-cus-es-01"

# default vars
location                              = "centralus"
kubernetes_version                    = "1.28.5"
identity_type                         = "SystemAssigned" # can be UserAssigned or SystemAssigned
node_resource_group                   = null             # may want to define this 
private_cluster_enabled               = false
role_based_access_control_enabled     = true
aks_role_based_access_control_enabled = true # Validate the purpose of azure_active_directory_role_based_access_control vs role_based_access_control_enabled
# vnet_id                               = ""
# private_dns_zone_type = "System"
private_dns_zone_id     = null
aks_sku_tier            = "Free"
aks_network_plugin      = "azure"
aks_network_policy      = "" # can be azure or calico
azure_policy_enabled    = true
service_cidr            = "10.0.0.0/16"
aks_pod_cidr            = "127.17.0.0/16" #"CIDR used by pods when network plugin is set to `kubenet`. https://docs.microsoft.com/en-us/azure/aks/configure-kubenet"
outbound_type           = "loadBalancer"
docker_bridge_cidr      = "172.17.0.1/16" #"IP address for docker with Network CIDR."
auto_scaler_profile     = null
aks_http_proxy_settings = null

default_node_pool = {
  "name"       = "systempool"
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
    "node_labels"            = { nodepool = "service" }
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
