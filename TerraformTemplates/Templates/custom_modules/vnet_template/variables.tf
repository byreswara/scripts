variable "location" {
  description = "Azure region to use"
  type        = string
}

variable "location_short" {
  description = "Short string for Azure location."
  type        = string
}

variable "custom_virtual_network_name" {
  description = "Custom vnet name"
  type        = string
  default     = ""
}

variable "subscription" {
  description = "Project environment"
  type        = string
}

variable "environment" {
  description = "Project environment"
  type        = string
  default     = "qa"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "vnet_cidr" {
  description = "The address space that is used by the virtual network"
  type        = list(string)
}

variable "dns_servers" {
  description = "List of IP addresses of DNS servers"
  type        = list(string)
  default     = []
}

variable "vnet_iteration" {
  description = "Iteration number for the vnet"
  type        = string
  default     = "01"
}
