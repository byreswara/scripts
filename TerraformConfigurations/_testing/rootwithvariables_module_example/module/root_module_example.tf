terraform {
  required_version = ">= 1.4.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.18"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

module "azure_network_security_group" {
  source = "./templates/nsg_template/v1"

  nsg_name            = var.nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name

  additional_rules = var.additional_rules
  deployer         = var.deployer
  ado_Project      = var.ado_Project
  ado_Repository   = var.ado_Repository
  ado_Branch       = var.ado_Branch
}