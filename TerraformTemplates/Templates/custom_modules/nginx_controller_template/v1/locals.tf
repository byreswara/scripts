locals {
    client_key = var.aks_client_key #try(var.aks_client_key, base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_key))
    client_certificate = var.aks_client_certificate # try(var.aks_client_certificate, base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_certificate))
    cluster_ca_certificate = var.aks_cluster_ca_certificate #try(var.aks_cluster_ca_certificate, base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config[0].cluster_ca_certificate))
    host = var.aks_host #try(var.aks_host, data.azurerm_kubernetes_cluster.aks_cluster.kube_config[0].host)
}


