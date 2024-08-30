locals {
  virtual_network_name = var.custom_virtual_network_name != "" ? var.custom_virtual_network_name : "vnet-${var.environment}-${var.location_short}-${var.vnet_iteration}"
}
