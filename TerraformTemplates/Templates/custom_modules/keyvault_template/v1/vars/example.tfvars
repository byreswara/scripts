key_vault_name          = "keyvault-qa-es-cus-01" # Naming Configuration
location                = "centralus" # Example: "eastus" | "centralus"
resource_group_name     = "rg-keyvault-qa"
sku_name                = "standard"

enabled_for_disk_encryption       = false
soft_delete_retention_days        = 7
purge_protection_enabled          = false
public_network_access_enabled     = false

access_policies = [
  {
    # group: sg.azure.k8.admin
    object_id = "a180a7cf-100c-4e4a-8a8f-9f8ba96163d5" 
    key_permissions = ["Get", "List"]
    secret_permissions = ["Get", "List"]
    certificate_permissions = ["Get", "List"]
  }
]
