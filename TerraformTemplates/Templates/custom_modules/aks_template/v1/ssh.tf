resource "azapi_resource_action" "ssh_public_key_gen" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_public_key.id
  action      = "generateKeyPair"
  method      = "POST"

  response_export_values = ["publicKey", "privateKey"]
}

resource "azapi_resource" "ssh_public_key" {
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name      = "ssh-${var.aks_name}"
  location  = var.location                                                       #data.azurerm_resource_group.aks_rg.location
  parent_id = var.resource_group_id                                                     # data.azurerm_resource_group.aks_rg.id
  tags      = merge(local.default_tags, var.extra_tags)
  lifecycle {
    ignore_changes = [
      tags["CreationDate"], tags["CreatedBy"],
    ]
  }
}

