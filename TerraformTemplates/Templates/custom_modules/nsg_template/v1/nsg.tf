resource "azurerm_network_security_group" "nsg" {
  name = var.nsg_name

  resource_group_name = var.resource_group_name
  location            = var.location

  tags = merge(local.default_tags, var.extra_tags)
  lifecycle {
    ignore_changes = [
      tags["CreationDate"], tags["CreatedBy"],
    ]
  }
}
