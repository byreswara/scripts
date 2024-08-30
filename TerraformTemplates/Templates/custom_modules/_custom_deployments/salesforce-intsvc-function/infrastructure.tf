# Get salesforce resource group
data "azurerm_resource_group" "rg_deployment" {
  name = local.project_rg
}

# Create Storage Account for function Data
resource "azurerm_storage_account" "storage_account_tcfunction" {
  name                              = lower("rgsalesforce${local.unique_stage}intsvc") # need to update for prod using variable
  resource_group_name               = local.project_rg
  location                          = var.location
  account_tier                      = "Standard"
  account_kind                      = "Storage"
  account_replication_type          = "LRS"
  enable_https_traffic_only         = true
  min_tls_version                   = "TLS1_2"
  cross_tenant_replication_enabled  = false
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = "true"
  table_encryption_key_type         = "Service"
  default_to_oauth_authentication   = "false"
  infrastructure_encryption_enabled = "false"
  is_hns_enabled                    = "false"

  tags = merge(local.common_tags)

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }

}

# resource "azurerm_storage_container" "storage_hostkeycontainer_tcfunction" {
#   name                  = "azure-webjobs-secrets"
#   storage_account_name  = azurerm_storage_account.storage_account_tcfunction.name
#   container_access_type = "private"
# }

#Get APIM
data "azurerm_api_management" "apim" {
  name                = "apim-${local.resource_suffix}"
  resource_group_name = local.project_rg
}


# Get container resource group
data "azurerm_resource_group" "rg_ContainerRegistry" {
  provider = azurerm.legacy
  name     = "ContainerRegistry"
}

# Get Trialcard Azure Container Registry
data "azurerm_container_registry" "acr" {
  provider            = azurerm.legacy
  name                = "trialcard"
  resource_group_name = data.azurerm_resource_group.rg_ContainerRegistry.name
}

# Get SalesforceUAT resource group
data "azurerm_resource_group" "rg_sf_keyvault" {
  provider = azurerm.identity
  name     = local.keyvault_rg
}

# Get Salesforce UAT Keyvault
data "azurerm_key_vault" "sf_keyvault" {
  provider            = azurerm.identity
  name                = local.keyvault_name
  resource_group_name = data.azurerm_resource_group.rg_sf_keyvault.name
}

# Get existing network configuration
data "azurerm_virtual_network" "tc_function_vnet" {
  name                = local.vnet_name # need to update for prod using variable
  resource_group_name = local.core_rg   # need to update for prod using variable
}

data "azurerm_subnet" "tc_function_subnet" {
  name                 = local.snet_name # need to update for prod using variable
  virtual_network_name = data.azurerm_virtual_network.tc_function_vnet.name
  resource_group_name  = local.core_rg # need to update for prod using variable
}

data "azurerm_log_analytics_workspace" "ai_salesforce_workspace" {
  name                = local.workspace_name
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
}

resource "azurerm_application_insights" "ai_salesforce_apim" {
  name                = local.ai_name
  location            = data.azurerm_resource_group.rg_deployment.location
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  workspace_id        = data.azurerm_log_analytics_workspace.ai_salesforce_workspace.id
  application_type    = "web"

  tags = merge(local.common_tags)

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}