locals {
  default_tags = var.default_tags_enabled ? {
    CreatedBy      = var.deployer
    LastUpdatedBy  = var.deployer
    DeployedBy     = "Terraform"
    ado_Project    = var.ado_Project
    ado_Repository = var.ado_Repository
    ado_Branch     = var.ado_Branch
    Location       = var.location
    CreationDate   = timestamp()
  } : {}
}
