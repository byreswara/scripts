service_name            = "keyvault-prod-cus-es-01" # Naming Configuration
location                = "centralus" # Example: "eastus" | "centralus"
resource_group_name     = "rg-keyvault-prod"
sku_name                = "standard"

enabled_for_disk_encryption       = false
soft_delete_retention_days        = 7
purge_protection_enabled          = false
public_network_access_enabled     = false

access_policies = [
  {
    # group: sg.azure.k8.admin
    object_id = "a180a7cf-100c-4e4a-8a8f-9f8ba96163d5" 
    key_permissions = ["Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"]
    secret_permissions = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"]
    certificate_permissions = ["Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"]
  }
]