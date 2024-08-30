# Set local variables used in the terraform script. Values are set through Variables.tf to centralize where changes are made
locals {
  project_rg       = var.ai_rg
  project_name     = var.project_name
  ai_name          = var.ai_name
  ai_alert         = var.ai_alert
  alert_enabled    = var.alert_enabled
  workspace_name   = var.workspace_name
  environment_name = var.environment_name
  location         = var.location
  actiongroup_id   = "/subscriptions/4a682cd3-695d-4f51-bcc9-f46835d20d4a/resourceGroups/rg-mgmt-core-01/providers/microsoft.insights/actiongroups/DevOps-PagerDuty-Alert"
  create_alert     = var.environment_name == "prod" ? true : false
}
