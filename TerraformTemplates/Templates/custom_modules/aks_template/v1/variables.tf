variable "aks_http_proxy_settings" {
  description = "AKS HTTP proxy settings. URLs must be in format `http(s)://fqdn:port/`. When setting the `no_proxy_url_list` parameter, the AKS Private Endpoint domain name and the AKS VNet CIDR must be added to the URLs list."
  type = object({
    http_proxy_url    = optional(string)
    https_proxy_url   = optional(string)
    no_proxy_url_list = optional(list(string), [])
    trusted_ca        = optional(string)
  })
  default = null
}

variable "aks_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "network_plugin_mode" {
  description = "Specifies the network plugin mode used for building the Kubernetes network. Possible value is overlay"
  type        = string
  default     = ""
}

variable "aks_network_plugin" {
  description = "AKS network plugin to use. Possible values are `azure` and `kubenet`. Changing this forces a new resource to be created"
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "kubenet"], var.aks_network_plugin)
    error_message = "The network plugin value must be \"azure\" or \"kubenet\"."
  }
}

variable "aks_network_policy" {
  description = "AKS network policy to use."
  type        = string
  default     = "calico"
}

variable "aks_pod_cidr" {
  description = "CIDR used by pods when network plugin is set to `kubenet`. https://docs.microsoft.com/en-us/azure/aks/configure-kubenet"
  type        = string
  default     = "172.17.0.0/16"
}

variable "aks_role_based_access_control_enabled" {
  description = "Enable AKS role based access control."
  type        = bool
  default     = true
}

variable "aks_sku_tier" {
  description = "aks sku tier. Possible values are Free ou Paid"
  type        = string
  default     = "Free"
}

variable "automatic_channel_upgrade" {
  description = "The channel to use for automatic upgrades. Possible values are `stable` and `rapid`."
  type        = string
  default     = "stable"
}

variable "auto_scaler_profile" {
  description = "Configuration of `auto_scaler_profile` block object"
  type = object({
    balance_similar_node_groups      = optional(bool, false)
    expander                         = optional(string, "random")
    max_graceful_termination_sec     = optional(number, 600)
    max_node_provisioning_time       = optional(string, "15m")
    max_unready_nodes                = optional(number, 3)
    max_unready_percentage           = optional(number, 45)
    new_pod_scale_up_delay           = optional(string, "10s")
    scale_down_delay_after_add       = optional(string, "10m")
    scale_down_delay_after_delete    = optional(string, "10s")
    scale_down_delay_after_failure   = optional(string, "3m")
    scan_interval                    = optional(string, "10s")
    scale_down_unneeded              = optional(string, "10m")
    scale_down_unready               = optional(string, "20m")
    scale_down_utilization_threshold = optional(number, 0.5)
    empty_bulk_delete_max            = optional(number, 10)
    skip_nodes_with_local_storage    = optional(bool, true)
    skip_nodes_with_system_pods      = optional(bool, true)
  })
  default = null
}

variable "azure_policy_enabled" {
  description = "Should the Azure Policy Add-On be enabled?"
  type        = bool
  default     = false
}

variable "container_registries_id" {
  description = "List of Azure Container Registries ids where AKS needs pull access."
  type        = list(string)
  default     = []
}

variable "default_node_pool" {
  description = "Default node pool configuration"
  type = object({
    name                   = optional(string, "default")
    node_count             = optional(number, 1)
    vm_size                = optional(string, "Standard_D2_v3")
    os_type                = optional(string, "Linux")
    zones                  = optional(list(number), [1, 2, 3])
    enable_auto_scaling    = optional(bool, false)
    min_count              = optional(number, 1)
    max_count              = optional(number, 10)
    type                   = optional(string, "VirtualMachineScaleSets")
    node_taints            = optional(list(any), null)
    node_labels            = optional(map(any), null)
    orchestrator_version   = optional(string, null)
    priority               = optional(string, null)
    enable_host_encryption = optional(bool, null)
    eviction_policy        = optional(string, null)
    max_pods               = optional(number, 30)
    os_disk_type           = optional(string, "Managed")
    os_disk_size_gb        = optional(number, 128)
    enable_node_public_ip  = optional(bool, false)
  })
  default = {}
}

variable "docker_bridge_cidr" {
  description = "IP address for docker with Network CIDR."
  type        = string
  default     = "172.16.0.1/16"
}

variable "identity_type" {
  description = "Type of identity to use for AKS. Possible values are `SystemAssigned` and `UserAssigned`."
  type        = string
  default     = "SystemAssigned"
}

variable "key_vault_name" {
  description = "Name of the Key Vault"
  type        = string
}

variable "key_vault_resource_group_name" {
  description = "Name of the Key Vault resource group"
  type        = string
}

variable "keyvault_id" {
  description = "ID of the Key Vault"
  type        = string
}

variable "key_vault_csi_driver_enabled" {
  description = "Enable Key Vault CSI driver"
  type        = bool
  default     = true
}

variable "key_vault_rotation_interval" {
  description = "Interval in seconds for the Key Vault secrets rotation"
  type        = string
  default     = "24h"
}

variable "key_vault_secrets_provider" {
  description = "Enable AKS built-in Key Vault secrets provider. If enabled, an identity is created by the AKS itself and exported from this module."
  type = object({
    secret_rotation_enabled  = optional(bool)
    secret_rotation_interval = optional(string)
  })
  default = null
}

variable "kubernetes_version" {
  description = "Version of Kubernetes to deploy"
  type        = string
  default     = "1.17.9"
}

variable "location" {
  description = "Azure region to use"
  type        = string
}

variable "nodes_pools" {
  description = "A list of nodes pools to create, each item supports same properties as `local.default_agent_profile`"
  type        = list(any)
  default     = []
}

variable "node_resource_group" {
  description = "Name of the resource group in which to put AKS nodes. If null default to MC_<AKS RG Name>"
  type        = string
  default     = null
}


variable "nodes_subnet_id" {
  description = "ID of the subnet used for nodes"
  type        = string
}


variable "private_cluster_enabled" {
  description = "Configure AKS as a Private Cluster: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#private_cluster_enabled"
  type        = bool
  default     = true
}

variable "private_dns_zone_id" {
  type        = string
  default     = null
  description = "Id of the private DNS Zone when <private_dns_zone_type> is custom"
}

variable "private_dns_zone_type" {
  type        = string
  default     = "System"
  description = <<EOD
Set AKS private dns zone if needed and if private cluster is enabled (privatelink.<region>.azmk8s.io)
- "Custom" : You will have to deploy a private Dns Zone on your own and pass the id with <private_dns_zone_id> variable
If this settings is used, aks user assigned identity will be "userassigned" instead of "systemassigned"
and the aks user must have "Private DNS Zone Contributor" role on the private DNS Zone
- "System" : AKS will manage the private zone and create it in the same resource group as the Node Resource Group
- "None" : In case of None you will need to bring your own DNS server and set up resolving, otherwise cluster will have issues after provisioning.

https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#private_dns_zone_id
EOD
}

variable "resource_group_name" {
  description = "Name of the AKS resource group"
  type        = string
}

variable "resource_group_id" {
  description = "Name of the AKS resource group"
  type        = string
}

variable "vnet_name" {
  description = "Name of the vnet"
  type        = string
}

variable "role_based_access_control_enabled" {
  description = "Whether to enable role-based access control for Kubernetes authorization."
  type        = bool
  default     = true
}


variable "service_cidr" {
  description = "CIDR used by kubernetes services (kubectl get svc)."
  type        = string
}

variable "outbound_type" {
  description = "The outbound (egress) routing method which should be used for this Kubernetes Cluster. Possible values are `loadBalancer` and `userDefinedRouting`."
  type        = string
  default     = "loadBalancer"
}

variable "vnet_id" {
  description = "Vnet id that Aks MSI should be network contributor in a private cluster"
  type        = string
  default     = null
}

variable "aks_private_dns_zone_id" {
  description = "ID of aks private dns zone"
  type        = string
}

variable "aks_subnet_id" {
  description = "ID of the aks subnet"
  type        = string
}

variable "vnet_resource_group_name" {
  description = "Name of the Vnet resource group"
  type        = string
}

variable "log_analytics_workspace_id" {
  type = string
  description = "ID of the existing Log Analytics Workspace"
}

variable "metric_labels_allowlist" {
  default = null
}

variable "metric_annotations_allowlist" {
  default = null
}

variable "iam_policies" {
  description = "IAM policies to assign to the principal."
  type = list(object({
    object_id = string
    role      = string
  }))
}