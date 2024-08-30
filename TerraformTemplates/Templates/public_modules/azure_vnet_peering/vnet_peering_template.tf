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

data "azurerm_resource_group" "rg1" {
  name = "rg-terratesting-qa"
}

data "azurerm_resource_group" "rg2" {
  name = "rg-terratesting-qa"
}


data "azurerm_virtual_network" "network1" {
  name                = "vnet_test"
  resource_group_name = data.azurerm_resource_group.rg1.name
}

data "azurerm_virtual_network" "network2" {
  name                = "vnet_test_peer"
  resource_group_name = data.azurerm_resource_group.rg2.name
}




module "azure_vnet_peering" {
  source  = "claranet/vnet-peering/azurerm"
  version = "5.1.0"

  providers = {
    azurerm.src = azurerm
    azurerm.dst = azurerm
  }

  vnet_src_id  = data.azurerm_virtual_network.network1.id
  vnet_dest_id = data.azurerm_virtual_network.network2.id

  allow_forwarded_src_traffic  = true
  allow_forwarded_dest_traffic = true

  allow_virtual_src_network_access  = true
  allow_virtual_dest_network_access = true

  depends_on = [ data.azurerm_virtual_network.network1, data.azurerm_virtual_network.network2 ]
}