# Pull azurerm provider config (SP used in ADO for role delegation)
data "azurerm_client_config" "current" {}

# Keyvault access policy
resource "azurerm_key_vault_access_policy" "salesforce_kv_access_policy" {
  provider       = azurerm.identity
  key_vault_id   = data.azurerm_key_vault.sf_keyvault.id
  tenant_id      = var.tenantId
  object_id      = azurerm_linux_function_app.tc_function_app.identity[0].principal_id
  #application_id = azurerm_linux_function_app.tc_function_app.identity[0].principal_id

  key_permissions = [
    "Get",
    "List"
  ]

  secret_permissions = [
    "Get",
    "List"
  ]


}

# Azure Keyvault Role Assignment
resource "azurerm_role_assignment" "tc_function_keyvault_role" {
  scope                = data.azurerm_key_vault.sf_keyvault.id
  role_definition_name = "reader"
  principal_id         = azurerm_linux_function_app.tc_function_app.identity[0].principal_id
  #delegated_managed_identity_resource_id = "${azurerm_linux_function_app.tc_function_app.identity[0].principal_id}"
}

# Azure Container Registry Role Assignment
resource "azurerm_role_assignment" "tc_function_acr_role" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "acrpull"
  principal_id         = azurerm_linux_function_app.tc_function_app.identity[0].principal_id
  # delegated_managed_identity_resource_id = "${azurerm_linux_function_app.tc_function_app.identity[0].principal_id}"
}