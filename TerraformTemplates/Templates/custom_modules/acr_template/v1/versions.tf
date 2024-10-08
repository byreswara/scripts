terraform {
  required_version = ">= 1.4.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.97.1"
    }
  }
  # backend "azurerm" {}
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}