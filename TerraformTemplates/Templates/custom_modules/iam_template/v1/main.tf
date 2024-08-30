resource "azurerm_role_assignment" "iam" {
  for_each             = { for index, policy in var.iam_policies : index => policy }
  scope                = var.iam_scope
  role_definition_name = each.value.role
  principal_id         = each.value.object_id
}



