# resource "helm_release" "csi_secrets_store_provider" {
#   depends_on       = [data.azurerm_kubernetes_cluster.aks_cluster]
#   name             = var.key_vault_name
#   repository       = var.csi_secrets_store_provider_azure_repo
#   chart            = var.csi_secrets_chart
#   namespace        = var.ingress_controller_namespace
#   values = [
#     file("../manifests/secretStore.yml")
#   ]
# }

resource "kubectl_manifest" "create_secret_prov_class" {
  # depends_on = [helm_release.csi_secrets_store_provider] 
  yaml_body = templatefile("${path.module}/manifests/secretProviderClassVar.yml",
    { namespace_name = var.ingress_controller_namespace,
      key_vault_name = var.key_vault_name,
      cert_name      = var.certificate_name,
  tenant_id = data.azurerm_subscription.current.tenant_id })
}

resource "helm_release" "create_ingress_controller" {
  depends_on = [kubectl_manifest.create_secret_prov_class]
  name       = var.ingress_nginx_name
  repository = var.ingress_controller_repo
  chart      = var.ingress_controller_chart
  namespace  = var.ingress_controller_namespace

  values = [
    templatefile("${path.module}/manifests/ingressControllerVar.yml",
      { key_vault_name = var.key_vault_name
    })
  ]
}
