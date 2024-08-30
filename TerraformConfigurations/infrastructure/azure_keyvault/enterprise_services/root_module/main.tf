
# Modules:
module "azure_keyvault" {
  source                        = "./modules/keyvault_template/v1"
  key_vault_name                = var.service_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  enabled_for_disk_encryption   = var.enabled_for_disk_encryption
  soft_delete_retention_days    = var.soft_delete_retention_days
  purge_protection_enabled      = var.purge_protection_enabled
  public_network_access_enabled = var.public_network_access_enabled
  deployer                      = var.deployer
  ado_Project                   = var.ado_Project
  ado_Repository                = var.ado_Repository
  ado_Branch                    = var.ado_Branch
  extra_tags                    = var.extra_tags
  access_policies               = var.access_policies
  sku_name                      = var.sku_name
}