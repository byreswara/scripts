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

  nsg_name            = "nsg-snet-afo-avd-cus-01-deploymenttesting"
  location            = "eastus"
  resource_group_name = "rg-terratesting-qa"
  deployer            = var.deployer

  additional_rules = [
    # Inbound Rules
    {
      priority  = 100
      name      = "Allow_ICMP_10.0.0.0_s8_In"
      direction = "Inbound"
      access    = "Allow"
      protocol  = "Icmp"
      source_port_range      = "*"
      destination_port_range = "*"
      source_address_prefix      = "10.0.0.0/8"
      destination_address_prefix = "*"
    },
    {
      priority  = 1000
      name      = "AllowTag_EntraID_TCP_In"
      direction = "Inbound"
      access    = "Allow"
      protocol  = "Tcp"
      source_port_range       = "*"
      destination_port_ranges = ["123", "137", "135", "138", "139", "389", "445", "464", "636", "1025-5000", "5722", "9389", "49152-65535"]
      source_address_prefix      = "AzureActiveDirectory"
      destination_address_prefix = "*"
    },
    {
      priority  = 1010
      name      = "AllowTag_EntraID_UDP_In"
      direction = "Inbound"
      access    = "Allow"
      protocol  = "Udp"
      source_port_range       = "*"
      destination_port_ranges = ["88", "123", "137", "138", "139", "389", "445", "464", "636", "2535"]
      source_address_prefix      = "AzureActiveDirectory"
      destination_address_prefix = "*"
    },
    {
      priority  = 1100
      name      = "AllowTag_EntraID-DS_TCP_In"
      direction = "Inbound"
      access    = "Allow"
      protocol  = "Tcp"
      source_port_range       = "*"
      destination_port_ranges = ["123", "137", "135", "138", "139", "389", "445", "464", "636", "1025-5000", "5722", "9389", "49152-65535"]
      source_address_prefix      = "AzureActiveDirectoryDomainServices"
      destination_address_prefix = "*"
    },
    {
      priority  = 1110
      name      = "AllowTag_EntraID-DS_UDP_In"
      direction = "Inbound"
      access    = "Allow"
      protocol  = "Udp"
      source_port_range       = "*"
      destination_port_ranges = ["88", "123", "137", "138", "139", "389", "445", "464", "636", "2535"]
      source_address_prefix      = "AzureActiveDirectoryDomainServices"
      destination_address_prefix = "*"
    },
    # Outbound Rules
    {
      priority  = 100
      name      = "Allow_ICMP_10.0.0.0_s8_Out"
      direction = "Outbound"
      access    = "Allow"
      protocol  = "Icmp"
      source_port_range      = "*"
      destination_port_range = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "10.0.0.0/8"
    },
    {
      priority  = 1000
      name      = "AllowTag_EntraID_TCP_Out"
      direction = "Outbound"
      access    = "Allow"
      protocol  = "Tcp"
      source_port_range       = "*"
      destination_port_ranges = ["123", "137", "135", "138", "139", "389", "445", "464", "636", "1025-5000", "5722", "9389", "49152-65535"]
      source_address_prefix      = "*"
      destination_address_prefix = "AzureActiveDirectory"
    },
    {
      priority  = 1010
      name      = "AllowTag_EntraID_UDP_Out"
      direction = "Outbound"
      access    = "Allow"
      protocol  = "Udp"
      source_port_range       = "*"
      destination_port_ranges = ["88", "123", "137", "138", "139", "389", "445", "464", "636", "2535"]
      source_address_prefix      = "*"
      destination_address_prefix = "AzureActiveDirectory"
    },
    {
      priority  = 1100
      name      = "AllowTag_EntraID-DS_TCP_Out"
      direction = "Outbound"
      access    = "Allow"
      protocol  = "Tcp"
      source_port_range       = "*"
      destination_port_ranges = ["123", "137", "135", "138", "139", "389", "445", "464", "636", "1025-5000", "5722", "9389", "49152-65535"]
      source_address_prefix      = "*"
      destination_address_prefix = "AzureActiveDirectoryDomainServices"
    },
    {
      priority  = 1110
      name      = "AllowTag_EntraID-DS_UDP_Out"
      direction = "Outbound"
      access    = "Allow"
      protocol  = "Udp"
      source_port_range       = "*"
      destination_port_ranges = ["88", "123", "137", "138", "139", "389", "445", "464", "636", "2535"]
      source_address_prefix      = "*"
      destination_address_prefix = "AzureActiveDirectoryDomainServices"
    }
  ]
}

variable "deployer" {
  description = "The name of the person deploying the resources"
  type        = string
}