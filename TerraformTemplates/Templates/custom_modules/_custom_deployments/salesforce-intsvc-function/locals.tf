locals {

  unique_stage    = lookup(var.stage_mapping, lower(var.stage)).unique_stage
  shared_stage    = lookup(var.stage_mapping, lower(var.stage)).shared_stage
  short_location  = lookup(var.location_mapping, lower(var.location)).short_name
  long_location   = lookup(var.location_mapping, lower(var.location)).long_name
  resource_suffix = local.unique_stage != "prod" ? "${local.project_name}-${local.short_location}-${local.unique_stage}" : "${local.project_name}-${local.short_location}"

  project_name       = var.project_name
  project_name_alnum = var.project_name_alnum
  project_rg         = local.unique_stage != "prod" ? "rg-salesforce-${local.unique_stage}-apim" : "rg-salesforce-apim-01"
  app_plan_tier      = local.unique_stage == "dev" ? "P1v2" : "P1v2"
  stage              = local.unique_stage
  keyvault_name      = local.unique_stage != "prod" ? "kv-salesforce-${local.stage}-01" : "kv-salesforce-prod-01"
  keyvault_rg        = local.unique_stage != "prod" ? "rg-ident-sf-${local.stage}-01" : "rg-ident-sf-prod-01"
  vnet_name          = local.unique_stage != "prod" ? "Vnet-salesforce-${local.stage}-central-01" : "Vnet-salesforce-central-01"
  snet_name          = local.unique_stage != "prod" ? "snet-salesforce-${local.stage}-PI-ASP-01" : "snet-salesforce-PI-ASP-01"
  core_rg            = local.unique_stage != "prod" ? "rg-salesforce-${local.stage}-core-01" : "rg-salesforce-core-01"
  workspace_name     = local.unique_stage != "prod" ? "workspace-salesforce-apim-${local.unique_stage}" : "workspace-salesforce-apim"
  ai_name            = local.unique_stage != "prod" ? "ai-salesforce-apim-${local.unique_stage}" : "ai-salesforce-apim"

}
