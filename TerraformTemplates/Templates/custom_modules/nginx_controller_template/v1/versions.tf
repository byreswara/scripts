terraform {
  required_version = ">= 1.4.2"
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
  backend "azurerm" {}
}

provider "helm" {
  debug   = true
  kubernetes {
    host = local.host
    client_key             = local.client_key
    client_certificate     = local.client_certificate
    cluster_ca_certificate = local.cluster_ca_certificate
  }
}

provider "kubernetes" {
  host                   = local.host
  client_key             = local.client_key
  client_certificate     = local.client_certificate
  cluster_ca_certificate = local.cluster_ca_certificate
  # load_config_file       = false
}