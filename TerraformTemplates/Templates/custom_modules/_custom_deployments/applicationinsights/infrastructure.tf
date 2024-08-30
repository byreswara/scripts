data "azurerm_resource_group" "rg_deployment" {
  name = local.project_rg
}

data "azurerm_log_analytics_workspace" "ai_workspace" {
  name                = local.workspace_name
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
}

resource "azurerm_application_insights" "ai_instance" {
  name                = local.ai_name
  location            = data.azurerm_resource_group.rg_deployment.location
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  workspace_id        = data.azurerm_log_analytics_workspace.ai_workspace.id
  application_type    = "web"
  daily_data_cap_in_gb = var.dataCap

  tags = merge(local.common_tags)

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}