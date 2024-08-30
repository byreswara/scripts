terraform {
  required_version = ">= 1.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.39"
    }
    azapi = {
      source  = "azure/azapi"
    }

  }
  backend "azurerm" {
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

provider "azapi" {
  skip_provider_registration = true
}
