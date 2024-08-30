output "network_security_group_id" {
  description = "Network security group ID"
  value       = azurerm_network_security_group.nsg.id
}

output "network_security_group_name" {
  description = "Network security group name"
  value       = azurerm_network_security_group.nsg.name
}

output "network_security_group_rg_name" {
  description = "Network security group resource group name"
  value       = var.resource_group_name
}