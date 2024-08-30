variable "aks_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "aks_resource_group_name" {
  description = "Name of the AKS resource group"
  type        = string
}

variable "certificate_name" {
  description = "Name of the certificate"
  type        = string

}

# variable "csi_secrets_chart" {
#   description = "Name of the CSI secrets store provider chart"
#   type        = string
#   default     = "secrets-store-csi-driver-provider-azure"
# }

# variable "csi_secrets_store_provider_azure_repo" {
#   description = "URL of the CSI secrets store provider Azure repository"
#   type        = string
#   default     = "https://raw.githubusercontent.com/Azure/secrets-store-csi-driver-provider-azure/master/charts"
# }

variable "aks_client_key" {
  description = "Client key for the AKS cluster"
  type        = string
  default     = null
}

variable "aks_client_certificate" {
  description = "Client certificate for the AKS cluster"
  type        = string
  default     = null
}

variable "aks_cluster_ca_certificate" {
  description = "Cluster CA certificate for the AKS cluster"
  type        = string
  default     = null
}

variable "aks_host" {
  description = "Host for the AKS cluster"
  type        = string
  default     = null
}

variable "ingress_controller_chart" {
  description = "Name of the ingress controller chart"
  type        = string
  default     = "ingress-nginx"
}


variable "ingress_controller_namespace" {
  description = "Namespace for the resources"
  type        = string
}

variable "ingress_controller_repo" {
  description = "URL of the ingress controller repository"
  type        = string
  default     = "https://kubernetes.github.io/ingress-nginx/"
}

variable "ingress_nginx_name" {
  description = "Name of the ingress controller"
  type        = string
  default     = "nginx-controller"
}

variable "key_vault_name" {
  description = "Name of the key vault"
  type        = string
}

# variable "manifest_path" {
#   description = "Path to the manifest files"
#   type        = string
# }
