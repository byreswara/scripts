
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.acr_sku
  admin_enabled       = var.admin_enabled
  zone_redundancy_enabled = var.zone_redundancy_enabled
  
  dynamic "georeplications" {
    for_each = var.georeplication_locations

    content {
      location = georeplications.value
      tags     = var.tags
      zone_redundancy_enabled = var.zone_redundancy_enabled
    }
  }

  tags = merge(local.default_tags, var.extra_tags)
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      tags["CreationDate"], tags["CreatedBy"],
    ]
  }
}