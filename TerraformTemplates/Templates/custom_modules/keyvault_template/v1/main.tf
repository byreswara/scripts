resource "azurerm_key_vault" "kv" {
  name                          = var.key_vault_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  enabled_for_disk_encryption   = var.enabled_for_disk_encryption
  tenant_id                     = data.azurerm_client_config.current.tenant_id #"e19ce0fc-2429-4a9e-b937-3ef24246c22c"
  soft_delete_retention_days    = var.soft_delete_retention_days
  purge_protection_enabled      = var.purge_protection_enabled
  public_network_access_enabled = var.public_network_access_enabled
  sku_name                      = var.sku_name
}

resource "azurerm_key_vault_access_policy" "kv_access_policy" {
  for_each                = { for index, policy in local.access_policies : index => policy }
  key_vault_id            = azurerm_key_vault.kv.id
  tenant_id               = data.azurerm_client_config.current.tenant_id
  object_id               = each.value.object_id
  key_permissions         = try(each.value.key_permissions, null)
  secret_permissions      = try(each.value.secret_permissions, null)
  certificate_permissions = try(each.value.certificate_permissions, null)
  storage_permissions     = try(each.value.storage_permissions, null)
}
