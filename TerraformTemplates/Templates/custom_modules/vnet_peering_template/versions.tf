terraform {
  required_version = ">= 1.3"
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "~> 3.0"
      configuration_aliases = [azurerm.src, azurerm.dst]
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~> 1.2, >= 1.2.22"
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

provider "azurecaf" {
}

provider "azurerm" {
  alias           = "dst"
  subscription_id = var.dest_subscription_id
  tenant_id       = var.tenant_id
  features {}
  skip_provider_registration = true
}
provider "azurerm" {
  alias           = "src"
  subscription_id = var.src_subscription_id
  tenant_id       = var.tenant_id
  features {}
  skip_provider_registration = true
}