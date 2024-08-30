terraform {
  required_version = ">= 1.1"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.18"
    }
  }
  backend "azurerm" {
    storage_account_name = var.storage_account_name
    container_name       = var.container_name
    key                  = var.key
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

data "azurerm_resource_group" "rg" {
  name = "rg-terratesting-qa"
}

module "vnet" {
  source  = "Azure/vnet/azurerm"
  version = "4.1.0"
  resource_group_name   = data.azurerm_resource_group.rg.name
  use_for_each = true
  vnet_location              = "Central US" # Optional; if not provided, will use Resource Group location
  vnet_name   = "vnet_test"
  address_space = ["10.82.8.0/22"]
  
  subnet_prefixes = ["10.82.11.0/24"]
  subnet_names = ["vnettestsubnet"]
  tags = {
    environment = "qa"
  }

  depends_on = [data.azurerm_resource_group.rg]
}

# data "azurerm_network_security_group" "nsg" {
#   name                = "nsg_test"
#   resource_group_name = data.azurerm_resource_group.rg.name
# }

# Optional inputs: https://registry.terraform.io/modules/Azure/vnet/azurerm/latest?tab=inputs
  # nsg_ids = {id = data.azurerm_network_security_group.nsg.id}
  # bgp_community = null
  # ddos_protection_plan = object({ enable = bool id = string })
  # dns_servers = list(string) Default: []
  # route_tables_ids = map(string) Default: {}
  # subnet_delegation = map(map(any)) Default: {}
  # subnet_enforce_private_link_endpoint_network_policies = map(bool) Default: {}
  # subnet_enforce_private_link_service_network_policies = map(bool) Default: {}
  # subnet_service_endpoints = map(any) Default: {}

  # tracing_tags_enabled = bool Default: false
  # tracing_tags_prefix = string Default: "avm_"
