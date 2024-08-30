terraform {
  required_version = ">= 1.4.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.97.1"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

# Modules:
module "azure_container_registry" {
  source = "./modules/acr_template/v1"

  acr_name                 = var.service_name
  location                 = var.location
  resource_group_name      = var.resource_group_name
  acr_sku                  = var.acr_sku
  admin_enabled            = var.admin_enabled
  deployer                 = var.deployer
  ado_Project              = var.ado_Project
  ado_Repository           = var.ado_Repository
  ado_Branch               = var.ado_Branch
  extra_tags               = var.extra_tags
  tags                     = var.tags
  georeplication_locations = var.georeplication_locations
  zone_redundancy_enabled  = var.zone_redundancy_enabled
}

module "acr-rbac" {
  source       = "./modules/iam_template/v1"
  iam_policies = var.iam_policies
  iam_scope    = module.azure_container_registry.id
}