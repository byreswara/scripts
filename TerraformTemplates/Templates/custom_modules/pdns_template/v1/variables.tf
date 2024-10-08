variable "private_dns_zone_name" {
  description = "(Required) Specifies the name of the private dns zone"
  type        = string
}

variable "resource_group_name" {
  description = "(Required) Specifies the resource group name of the private dns zone"
  type        = string
}

variable "tags" {
  description = "(Optional) Specifies the tags of the private dns zone"
  default     = {}
}

variable "vnet_link_name" {
  description = "(Required) Specifies the name of the virtual network link name"
  type        = string
}

variable "vnet_name" {
  description = "(Required) Specifies the name of the virtual network name"
  type        = string
}

variable "virtual_networks_to_link" {
  description = "(Optional) Specifies the subscription id, resource group name, and name of the virtual networks to which create a virtual network link"
  type        = map(any)
  default     = {}
}