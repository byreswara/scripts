variable "key_vault_name" {
  type        = string
  description = "The name of the keyvault instance"
}

variable "location" {
  type        = string
  default     = "centralus"
  description = "The location for all resources"
}

variable "resource_group_name" {
  type        = string
  description = "The resource group hosting the keyvault instance"
}

variable "enabled_for_disk_encryption" {
  type        = bool
  default     = false
  description = "Enable disk encryption for the keyvault"
}

variable "soft_delete_retention_days" {
  type        = number
  default     = 7
  description = "The number of days to retain soft deleted keys"
}

variable "purge_protection_enabled" {
  type        = bool
  default     = false
  description = "Enable purge protection for the keyvault"
}

variable "public_network_access_enabled" {
  type        = bool
  default     = false
  description = "Enable public network access for the keyvault"
}

variable "sku_name" {
  type        = string
  default     = "standard"
  description = "The SKU name for the keyvault"
}

variable "access_policies" {
  description = "Access policies for keyvault."
  type = list(object({
    object_id               = string
    key_permissions         = optional(list(string), null)
    secret_permissions      = optional(list(string), null)
    certificate_permissions = optional(list(string), null)
    storage_permissions     = optional(list(string), null)
  }))
  default = []
}
