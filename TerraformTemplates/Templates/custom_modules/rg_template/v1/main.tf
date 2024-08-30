resource "azurerm_resource_group" "rg" {
  location = var.location
  name     = var.name
  
  tags = merge(local.default_tags, var.extra_tags)
  lifecycle {
    ignore_changes = [
      tags["CreationDate"], tags["CreatedBy"],
    ]
  }
}