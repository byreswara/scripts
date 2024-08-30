# rbac variables:
iam_policies = [
  {
    # group: sg.azure.k8.admin
    object_id = "a180a7cf-100c-4e4a-8a8f-9f8ba96163d5"
    role      = "Azure Kubernetes Service RBAC Cluster Admin"
  },
  {
    # group: sg.IT.devs.AZMig.eng.devops.ctr
    object_id = "00563e91-667a-4eed-b6e4-5e4658c8fbcf"
    role      = "Azure Kubernetes Service RBAC Cluster Admin"
  },
  {
    # group: sg.IT.devs.AZMig.eng.devops.ctr
    object_id = "00563e91-667a-4eed-b6e4-5e4658c8fbcf"
    role      = "Azure Kubernetes Service Contributor Role"
  }
]

grafana_iam_policies = [
  {
    # group: sg.azure.k8.admin
    object_id = "a180a7cf-100c-4e4a-8a8f-9f8ba96163d5"
    role      = "Grafana Admin"
  },
  {
    # group: sg.IT.devs.AZMig.eng.devops.ctr
    object_id = "00563e91-667a-4eed-b6e4-5e4658c8fbcf"
    role      = "Grafana Admin"
  }
]

Identity_subscription_name = "2623c32f-9af1-458f-bae6-b367184b5386"

# tag variables:
default_tags_enabled   = true
extra_tags             = {}
default_node_pool_tags = {}

# subnets data source variables:
vnet_name                = "vnet-qa-central-01"
vnet_resource_group_name = "rg-qa-core-01"   

# keyvault data source variables:

key_vault_name                = "keyvault-qa-cus-es-01"     # TCkeyvault-qa1
key_vault_resource_group_name = "rg-keyvault-qa"            # keyvault-qa-rg

# acr data source variables:
acr_name                = "mercalisqa"
acr_resource_group_name = "rg-acr-qa"

# aks name variables:
aks_name            = "aks-qa-cus-es-01"
resource_group_name = "rg-aks-qa-cus-es-01"

# default variables:
location                              = "centralus"
kubernetes_version                    = "1.28.10"                                   # "1.28.9"
identity_type                         = "UserAssigned" # can be UserAssigned or SystemAssigned
node_resource_group                   = null             # may want to define this 
private_cluster_enabled               = true
role_based_access_control_enabled     = true
aks_role_based_access_control_enabled = true # Validate the purpose of azure_active_directory_role_based_access_control vs role_based_access_control_enabled
private_dns_zone_type   = "Custom"    # it can be Custom or System
aks_sku_tier            = "Free"
aks_network_plugin      = "azure"
aks_network_policy      = "" # can be azure or calico
network_plugin_mode     = "overlay"
azure_policy_enabled    = true
service_cidr            = "10.0.0.0/16"
aks_pod_cidr            = "192.168.0.0/16" #"CIDR used by pods when network plugin is set to `kubenet`. https://docs.microsoft.com/en-us/azure/aks/configure-kubenet"
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
    "name"       = "applications"
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
    "mode"                   = "User"
  }
]

# NSG and Subnet varaibles
# snet-<App / Service name>-<subscription>-<##>
subnet_name                   = "snet-k8cni-qa-cus-01"
location_short                = "cus"
environment                   = "qa"
subnet_cidr_list              = ["10.82.176.0/21"]               # 10.82.176.0/21 02 range
route_table_name              = null #"rt-test"
route_table_rg                = null #"rg-terratesting-qa"
route_table_id                = null
service_endpoints             = null # example: ["Microsoft.AzureActiveDirectory", "Microsoft.AzureCosmosDB"]
service_endpoint_policy_ids   = null #[]
private_link_endpoint_enabled = null
private_link_service_enabled  = null
subnet_delegation = {}

# NSG Values
nsg_name        = "nsg-snet-k8cni-qa-cus-01" # Naming Configuration
nsg_resource_group_name = "rg-qa-core-01"

 additional_rules = [
  # Inbound Rules
  {
    priority  = 100
    name      = "AllowAnyDNS-TCPInbound"
    direction = "Inbound"
    access    = "Allow"
    protocol  = "Tcp"

    source_port_range       = "*"
    destination_port_ranges = ["53"]

    source_address_prefix      = "*"
    destination_address_prefix = "*"
  },
  {
    priority  = 110
    name      = "AllowAnyDNS-UDPInbound"
    direction = "Inbound"
    access    = "Allow"
    protocol  = "Udp"

    source_port_range       = "*"
    destination_port_ranges = ["53"]

    source_address_prefix      = "*"
    destination_address_prefix = "*"
  },
  {
    priority  = 140
    name      = "AllowAnyHTTPSInbound"
    direction = "Inbound"
    access    = "Allow"
    protocol  = "Tcp"

    source_port_range       = "*"
    destination_port_ranges = ["443"]

    source_address_prefix      = "*"
    destination_address_prefix = "*"
  },
  # Outbound Rules
  {
    priority  = 120
    name      = "AllowAnyDNS-TCPOutbound"
    direction = "Outbound"
    access    = "Allow"
    protocol  = "Tcp"

    source_port_range       = "*"
    destination_port_ranges = ["53"]

    source_address_prefix      = "*"
    destination_address_prefix = "*"
  },
  {
    priority  = 130
    name      = "AllowAnyDNS-UDPOutbound"
    direction = "Outbound"
    access    = "Allow"
    protocol  = "Udp"

    source_port_range       = "*"
    destination_port_ranges = ["53"]

    source_address_prefix      = "*"
    destination_address_prefix = "*"
  },
  {
    priority  = 150
    name      = "AllowAnyHTTPSOutbound"
    direction = "Outbound"
    access    = "Allow"
    protocol  = "Tcp"

    source_port_range       = "*"
    destination_port_ranges = ["443"]

    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
 ]

log_analytics_workspace_name      = "DefaultWorkspace-9b28bd6c-83d4-4721-b1e9-cec8810ab5f9-CUS"
log_analytics_resource_group_name = "defaultresourcegroup-cus"
