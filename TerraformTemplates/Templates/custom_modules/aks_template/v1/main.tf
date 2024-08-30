#tfsec:ignore:azure-container-use-rbac-permissions
resource "azurerm_kubernetes_cluster" "aks" {
  name                              = var.aks_name
  location                          = var.location
  resource_group_name               = var.resource_group_name
  automatic_channel_upgrade         = var.automatic_channel_upgrade
  dns_prefix                        = replace(var.aks_name, "/[\\W_]/", "-")
  kubernetes_version                = var.kubernetes_version
  sku_tier                          = var.aks_sku_tier
  node_resource_group               = var.node_resource_group
  private_cluster_enabled           = var.private_cluster_enabled
  private_dns_zone_id               = var.private_cluster_enabled ? local.private_dns_zone : null
  role_based_access_control_enabled = var.role_based_access_control_enabled # Defaults to true
  azure_policy_enabled              = var.azure_policy_enabled

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = var.aks_role_based_access_control_enabled
    managed            = var.aks_role_based_access_control_enabled     # "managed" is deprecated: Reason: ""Terraform
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }

  default_node_pool {
    name                = local.default_node_pool.name
    vm_size             = local.default_node_pool.vm_size
    zones               = local.default_node_pool.zones
    enable_auto_scaling = local.default_node_pool.enable_auto_scaling
    node_count          = local.default_node_pool.enable_auto_scaling ? null : local.default_node_pool.node_count
    min_count           = local.default_node_pool.enable_auto_scaling ? local.default_node_pool.min_count : null
    max_count           = local.default_node_pool.enable_auto_scaling ? local.default_node_pool.max_count : null
    max_pods            = local.default_node_pool.max_pods
    os_disk_type        = local.default_node_pool.os_disk_type
    os_disk_size_gb     = local.default_node_pool.os_disk_size_gb
    type                = local.default_node_pool.type
    vnet_subnet_id      = local.default_node_pool.vnet_subnet_id
    node_labels         = local.default_node_pool.node_labels
    tags                = merge(local.default_tags, var.default_node_pool_tags)
  }

  identity {
    type = var.identity_type
    identity_ids = [azurerm_user_assigned_identity.aks_umi.id]
  }

  microsoft_defender {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }
  
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  monitor_metrics {
    annotations_allowed = var.metric_annotations_allowlist
    labels_allowed      = var.metric_labels_allowlist
  }

  dynamic "auto_scaler_profile" {
    for_each = var.auto_scaler_profile != null ? [var.auto_scaler_profile] : []
    content {
      balance_similar_node_groups      = try(auto_scaler_profile.value.balance_similar_node_groups, null)
      expander                         = try(auto_scaler_profile.value.expander, null)
      max_graceful_termination_sec     = try(auto_scaler_profile.value.max_graceful_termination_sec, null)
      max_node_provisioning_time       = try(auto_scaler_profile.value.max_node_provisioning_time, null)
      max_unready_nodes                = try(auto_scaler_profile.value.max_unready_nodes, null)
      max_unready_percentage           = try(auto_scaler_profile.value.max_unready_percentage, null)
      new_pod_scale_up_delay           = try(auto_scaler_profile.value.new_pod_scale_up_delay, null)
      scale_down_delay_after_add       = try(auto_scaler_profile.value.scale_down_delay_after_add, null)
      scale_down_delay_after_delete    = try(auto_scaler_profile.value.scale_down_delay_after_delete, null)
      scale_down_delay_after_failure   = try(auto_scaler_profile.value.scale_down_delay_after_failure, null)
      scan_interval                    = try(auto_scaler_profile.value.scan_interval, null)
      scale_down_unneeded              = try(auto_scaler_profile.value.scale_down_unneeded, null)
      scale_down_unready               = try(auto_scaler_profile.value.scale_down_unready, null)
      scale_down_utilization_threshold = try(auto_scaler_profile.value.scale_down_utilization_threshold, null)
      empty_bulk_delete_max            = try(auto_scaler_profile.value.empty_bulk_delete_max, null)
      skip_nodes_with_local_storage    = try(auto_scaler_profile.value.skip_nodes_with_local_storage, null)
      skip_nodes_with_system_pods      = try(auto_scaler_profile.value.skip_nodes_with_system_pods, null)
    }
  }

  # This is the admin username for the cluster, requires ssh key? Docs says required
  # dynamic "linux_profile" {
  #   for_each = var.linux_profile != null ? [true] : []
  #   iterator = lp
  #   content {
  #     admin_username = var.linux_profile.username

  #     ssh_key {
  #       key_data = var.linux_profile.ssh_key
  #     }
  #   }
  # }

  # Optional
  dynamic "http_proxy_config" {
    for_each = var.aks_http_proxy_settings != null ? ["enabled"] : []
    content {
      http_proxy  = var.aks_http_proxy_settings.http_proxy_url
      https_proxy = var.aks_http_proxy_settings.https_proxy_url
      no_proxy    = distinct(flatten(concat(local.default_no_proxy_url_list, var.aks_http_proxy_settings.no_proxy_url_list)))
      trusted_ca  = var.aks_http_proxy_settings.trusted_ca
    }
  }

  network_profile {
    network_plugin    = var.aks_network_plugin
    network_policy    = var.aks_network_plugin == "azure" ? "azure" : var.aks_network_policy
    network_mode      = var.aks_network_plugin == "azure" ? "transparent" : null
    dns_service_ip    = cidrhost(var.service_cidr, 10)
    service_cidr      = var.service_cidr
    load_balancer_sku = "standard"
    outbound_type     = var.outbound_type
    # pod_cidr          = var.aks_network_plugin == "kubenet" ? var.aks_pod_cidr : null
    pod_cidr          = var.aks_network_plugin == "kubenet" || var.network_plugin_mode == "overlay" ? var.aks_pod_cidr : null
    network_plugin_mode = var.network_plugin_mode
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = var.key_vault_csi_driver_enabled
    secret_rotation_interval = var.key_vault_rotation_interval
  }
  tags = merge(local.default_tags, var.extra_tags)
  lifecycle {
    ignore_changes = [
      tags["CreationDate"], tags["CreatedBy"],
    ]
  }
}

resource "azurerm_monitor_workspace" "prometheus" {
  name                = "prom-${var.aks_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_dashboard_grafana" "grafana" {
  name                              = "graf-${var.aks_name}"    
  resource_group_name               = var.resource_group_name
  location                          = var.location
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = false
  public_network_access_enabled     = true
  identity {
    type = "SystemAssigned"
  }
  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.prometheus.id
  }
}

resource "azurerm_monitor_data_collection_endpoint" "dce" {
  name                = "MSProm-${azurerm_monitor_workspace.prometheus.location}-${azurerm_kubernetes_cluster.aks.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  kind                = "Linux"
}
 
resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                = "MSProm-${azurerm_monitor_workspace.prometheus.location}-${azurerm_kubernetes_cluster.aks.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce.id
  kind                        = "Linux"
  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.prometheus.id
      name               = "MonitoringAccount1"
    }
  }
  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["MonitoringAccount1"]
  }
  data_sources {
    prometheus_forwarder {
      streams = ["Microsoft-PrometheusMetrics"]
      name    = "PrometheusDataSource"
    }
  }
  description = "DCR for Azure Monitor Metrics Profile (Managed Prometheus)"
  depends_on = [
    azurerm_monitor_data_collection_endpoint.dce
  ]
}
 
resource "azurerm_monitor_data_collection_rule_association" "dcra" {
  name                    = "MSProm-${azurerm_monitor_workspace.prometheus.location}-${azurerm_kubernetes_cluster.aks.name}"
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr.id
  target_resource_id      = azurerm_kubernetes_cluster.aks.id
  description             = "Association of data collection rule. Deleting this association will break the data collection for this AKS Cluster."
  depends_on = [
    azurerm_monitor_data_collection_rule.dcr
  ]
}

resource "azurerm_monitor_diagnostic_setting" "aks_settings" {
  name                       = "DiagnosticsSettings"
  target_resource_id         = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
 
  enabled_log {
    category = "kube-apiserver"
  }
 
  enabled_log {
    category = "kube-audit"
  }
 
  enabled_log {
    category = "kube-audit-admin"
  }
 
  enabled_log {
    category = "kube-controller-manager"
  }
 
  enabled_log {
    category = "kube-scheduler"
  }
 
  enabled_log {
    category = "cluster-autoscaler"
  }
 
  enabled_log {
    category = "guard"
  }
 
  metric {
    category = "AllMetrics"
  }
}

resource "azapi_resource" "NodeRecordingRulesRuleGroup" {
  type      = "Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01"
  name      = "NodeRecordingRulesRuleGroup-${azurerm_kubernetes_cluster.aks.name}"
  location  = var.location
  parent_id = var.resource_group_id
  body = jsonencode({
    "properties" : {
      "scopes" : [
        azurerm_monitor_workspace.prometheus.id
      ],
      "clusterName" : azurerm_kubernetes_cluster.aks.name,
      "interval" : "PT1M",
      "rules" : [
        {
          "record" : "instance:node_num_cpu:sum",
          "expression" : "count without (cpu, mode) (  node_cpu_seconds_total{job=\"node\",mode=\"idle\"})"
        },
        {
          "record" : "instance:node_cpu_utilisation:rate5m",
          "expression" : "1 - avg without (cpu) (  sum without (mode) (rate(node_cpu_seconds_total{job=\"node\", mode=~\"idle|iowait|steal\"}[5m])))"
        },
        {
          "record" : "instance:node_load1_per_cpu:ratio",
          "expression" : "(  node_load1{job=\"node\"}/  instance:node_num_cpu:sum{job=\"node\"})"
        },
        {
          "record" : "instance:node_memory_utilisation:ratio",
          "expression" : "1 - (  (    node_memory_MemAvailable_bytes{job=\"node\"}    or    (      node_memory_Buffers_bytes{job=\"node\"}      +      node_memory_Cached_bytes{job=\"node\"}      +      node_memory_MemFree_bytes{job=\"node\"}      +      node_memory_Slab_bytes{job=\"node\"}    )  )/  node_memory_MemTotal_bytes{job=\"node\"})"
        },
        {
          "record" : "instance:node_vmstat_pgmajfault:rate5m",
          "expression" : "rate(node_vmstat_pgmajfault{job=\"node\"}[5m])"
        },
        {
          "record" : "instance_device:node_disk_io_time_seconds:rate5m",
          "expression" : "rate(node_disk_io_time_seconds_total{job=\"node\", device!=\"\"}[5m])"
        },
        {
          "record" : "instance_device:node_disk_io_time_weighted_seconds:rate5m",
          "expression" : "rate(node_disk_io_time_weighted_seconds_total{job=\"node\", device!=\"\"}[5m])"
        },
        {
          "record" : "instance:node_network_receive_bytes_excluding_lo:rate5m",
          "expression" : "sum without (device) (  rate(node_network_receive_bytes_total{job=\"node\", device!=\"lo\"}[5m]))"
        },
        {
          "record" : "instance:node_network_transmit_bytes_excluding_lo:rate5m",
          "expression" : "sum without (device) (  rate(node_network_transmit_bytes_total{job=\"node\", device!=\"lo\"}[5m]))"
        },
        {
          "record" : "instance:node_network_receive_drop_excluding_lo:rate5m",
          "expression" : "sum without (device) (  rate(node_network_receive_drop_total{job=\"node\", device!=\"lo\"}[5m]))"
        },
        {
          "record" : "instance:node_network_transmit_drop_excluding_lo:rate5m",
          "expression" : "sum without (device) (  rate(node_network_transmit_drop_total{job=\"node\", device!=\"lo\"}[5m]))"
        }
      ]
    }
  })
 
  schema_validation_enabled = false
  ignore_missing_property   = false
}
 
resource "azapi_resource" "KubernetesRecordingRulesRuleGroup" {
  type      = "Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01"
  name      = "KubernetesReccordingRulesRuleGroup-${azurerm_kubernetes_cluster.aks.name}"
  location  = var.location
  parent_id = var.resource_group_id
  body = jsonencode({
    "properties" : {
      "scopes" : [
        azurerm_monitor_workspace.prometheus.id
      ],
      "clusterName" : azurerm_kubernetes_cluster.aks.name,
      "interval" : "PT1M",
      "rules" : [
        {
          "record" : "node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate",
          "expression" : "sum by (cluster, namespace, pod, container) (  irate(container_cpu_usage_seconds_total{job=\"cadvisor\", image!=\"\"}[5m])) * on (cluster, namespace, pod) group_left(node) topk by (cluster, namespace, pod) (  1, max by(cluster, namespace, pod, node) (kube_pod_info{node!=\"\"}))"
        },
        {
          "record" : "node_namespace_pod_container:container_memory_working_set_bytes",
          "expression" : "container_memory_working_set_bytes{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
        },
        {
          "record" : "node_namespace_pod_container:container_memory_rss",
          "expression" : "container_memory_rss{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
        },
        {
          "record" : "node_namespace_pod_container:container_memory_cache",
          "expression" : "container_memory_cache{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
        },
        {
          "record" : "node_namespace_pod_container:container_memory_swap",
          "expression" : "container_memory_swap{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
        },
        {
          "record" : "cluster:namespace:pod_memory:active:kube_pod_container_resource_requests",
          "expression" : "kube_pod_container_resource_requests{resource=\"memory\",job=\"kube-state-metrics\"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) (  (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1))"
        },
        {
          "record" : "namespace_memory:kube_pod_container_resource_requests:sum",
          "expression" : "sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_requests{resource=\"memory\",job=\"kube-state-metrics\"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~\"Pending|Running\"} == 1        )    ))"
        },
        {
          "record" : "cluster:namespace:pod_cpu:active:kube_pod_container_resource_requests",
          "expression" : "kube_pod_container_resource_requests{resource=\"cpu\",job=\"kube-state-metrics\"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) (  (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1))"
        },
        {
          "record" : "namespace_cpu:kube_pod_container_resource_requests:sum",
          "expression" : "sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_requests{resource=\"cpu\",job=\"kube-state-metrics\"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~\"Pending|Running\"} == 1        )    ))"
        },
        {
          "record" : "cluster:namespace:pod_memory:active:kube_pod_container_resource_limits",
          "expression" : "kube_pod_container_resource_limits{resource=\"memory\",job=\"kube-state-metrics\"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) (  (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1))"
        },
        {
          "record" : "namespace_memory:kube_pod_container_resource_limits:sum",
          "expression" : "sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_limits{resource=\"memory\",job=\"kube-state-metrics\"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~\"Pending|Running\"} == 1        )    ))"
        },
        {
          "record" : "cluster:namespace:pod_cpu:active:kube_pod_container_resource_limits",
          "expression" : "kube_pod_container_resource_limits{resource=\"cpu\",job=\"kube-state-metrics\"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) ( (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1) )"
        },
        {
          "record" : "namespace_cpu:kube_pod_container_resource_limits:sum",
          "expression" : "sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_limits{resource=\"cpu\",job=\"kube-state-metrics\"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~\"Pending|Running\"} == 1        )    ))"
        },
        {
          "record" : "namespace_workload_pod:kube_pod_owner:relabel",
          "expression" : "max by (cluster, namespace, workload, pod) (  label_replace(    label_replace(      kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"ReplicaSet\"},      \"replicaset\", \"$1\", \"owner_name\", \"(.*)\"    ) * on(replicaset, namespace) group_left(owner_name) topk by(replicaset, namespace) (      1, max by (replicaset, namespace, owner_name) (        kube_replicaset_owner{job=\"kube-state-metrics\"}      )    ),    \"workload\", \"$1\", \"owner_name\", \"(.*)\"  ))",
          "labels" : {
            "workload_type" : "deployment"
          }
        },
        {
          "record" : "namespace_workload_pod:kube_pod_owner:relabel",
          "expression" : "max by (cluster, namespace, workload, pod) (  label_replace(    kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"DaemonSet\"},    \"workload\", \"$1\", \"owner_name\", \"(.*)\"  ))",
          "labels" : {
            "workload_type" : "daemonset"
          }
        },
        {
          "record" : "namespace_workload_pod:kube_pod_owner:relabel",
          "expression" : "max by (cluster, namespace, workload, pod) (  label_replace(    kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"StatefulSet\"},    \"workload\", \"$1\", \"owner_name\", \"(.*)\"  ))",
          "labels" : {
            "workload_type" : "statefulset"
          }
        },
        {
          "record" : "namespace_workload_pod:kube_pod_owner:relabel",
          "expression" : "max by (cluster, namespace, workload, pod) (  label_replace(    kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"Job\"},    \"workload\", \"$1\", \"owner_name\", \"(.*)\"  ))",
          "labels" : {
            "workload_type" : "job"
          }
        },
        {
          "record" : ":node_memory_MemAvailable_bytes:sum",
          "expression" : "sum(  node_memory_MemAvailable_bytes{job=\"node\"} or  (    node_memory_Buffers_bytes{job=\"node\"} +    node_memory_Cached_bytes{job=\"node\"} +    node_memory_MemFree_bytes{job=\"node\"} +    node_memory_Slab_bytes{job=\"node\"}  )) by (cluster)"
        },
        {
          "record" : "cluster:node_cpu:ratio_rate5m",
          "expression" : "sum(rate(node_cpu_seconds_total{job=\"node\",mode!=\"idle\",mode!=\"iowait\",mode!=\"steal\"}[5m])) by (cluster) /count(sum(node_cpu_seconds_total{job=\"node\"}) by (cluster, instance, cpu)) by (cluster)"
        }
      ]
    }
  })
 
  schema_validation_enabled = false
  ignore_missing_property   = false
}