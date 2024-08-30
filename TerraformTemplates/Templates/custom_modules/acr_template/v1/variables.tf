variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  type        = string
  default     = "centralus"
}

variable "resource_group_name" {
  description = "The name of the resource group in which all resources in this example should be created."
  type        = string
}

variable "acr_name" {
    description = "The name of the Azure Container Registry."
    type        = string
}

variable "acr_sku" {
    description = "The SKU name of the Azure Container Registry."
    type        = string
    default     = "Standard"
}

variable "admin_enabled" {
    description = "Specifies whether the admin user is enabled."
    type        = bool
    default     = false
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