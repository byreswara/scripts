terraform {
  required_version = ">= 1.4.2"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.97.1"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 1.14.0"
    }

  }
  backend "azurerm" {
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

provider "azurerm" {
  alias = "Identity"
  subscription_id = var.Identity_subscription_name
  features {}
  skip_provider_registration = true
}

provider "azapi" {
  skip_provider_registration = true
}
