variable "service_name" {
  description = "Network security group name"
  type        = string
}

variable "location" {
  description = "Azure location."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "acr_sku" {
  description = "The SKU name of the the Azure Container Registry"
  type        = string
}

variable "admin_enabled" {
  description = "Is the admin user enabled"
  type        = bool
}

variable "tags" {
  description = "(Optional) A mapping of tags to assign to the resource."
  type        = map(any)
  default     = {}
}

variable "georeplication_locations" {
  description = "(Optional) A list of Azure locations where the container registry should be geo-replicated."
  type        = list(string)
  default     = []
}

variable "zone_redundancy_enabled" {
    description = "Specifies whether the zone redundancy is enabled."
    type        = bool
    default     = false
}