variable "environment" {
  type = string
}

variable "azauto_name" {
  type = string
}

variable "azauto_location" {
  type = string
  default = "centralus"
}

variable "azauto_rg_name" {
  type = string
}


locals {
  environment     = var.environment
  azauto_name     = var.azauto_name
  azauto_location = var.azauto_location
  azauto_rg_name  = var.azauto_rg_name
}

