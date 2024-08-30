resource "azurerm_monitor_metric_alert" "alert" {
  count               = local.create_alert ? 1 : 0
  name                = local.ai_alert
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  scopes              = [azurerm_application_insights.ai_instance.id]
  description         = "This Alert polls every 1 minute, checking if the AspNetCoreHealthCheckStatus metric is less than 1 (unhealthy) in the past 5 minutes"
  window_size         = "PT5M"
  frequency           = "PT1M"
  severity            = 0
  enabled             = local.alert_enabled

  criteria {
    metric_namespace       = "Azure.ApplicationInsights"
    metric_name            = "AspNetCoreHealthCheckStatus"
    aggregation            = "Minimum"
    operator               = "LessThan"
    threshold              = 1
    skip_metric_validation = true
  }

  action {
    action_group_id = local.actiongroup_id
  }

  tags = merge(local.common_tags)

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# Enhancement: Add data point for the action group ID and remove hardcoded variable. Requires adding the Management subscription as a provider in the main.tf file. Reference value: data.azurerm_monitor_action_group.devops_pagerduty.id
# data "azurerm_monitor_action_group" "devops_pagerduty" {
#   resource_group_name = "rg-mgmt-core-01"
#   name                = "DevOps-PagerDuty-Alert"
# }
