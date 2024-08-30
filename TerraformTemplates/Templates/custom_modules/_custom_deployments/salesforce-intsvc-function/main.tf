# 1. Configure the Azure provider

provider "azurerm" {
  #    version = "2.26.0"
  features {}
  skip_provider_registration = true
}

provider "azapi" {
  skip_provider_registration = true
}

# Provider for legacy subscription
provider "azurerm" {
  alias                      = "legacy"
  subscription_id            = "d0472d92-ce97-4986-8472-e08ba20ce8eb"
  skip_provider_registration = true
  features {}
}

# Provider for legacy subscription
provider "azurerm" {
  alias                      = "identity"
  subscription_id            = "2623c32f-9af1-458f-bae6-b367184b5386"
  skip_provider_registration = true
  features {}
}


# 2. Configure Terraform
terraform {
  required_version = "1.3.1"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.26.0"
    }

    azapi = {
      source = "azure/azapi"
    }
  }
  backend "azurerm" {
  }
}
