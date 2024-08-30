########################################################
#           Trialcard Az Container Deployment          #
########################################################

# Premium service plan for containerized az function
resource "azurerm_service_plan" "appserviceplancontainer" {
  name                = "container-service-plan-${local.short_location}-${local.unique_stage}"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  location            = data.azurerm_resource_group.rg_deployment.location
  os_type             = "Linux"
  sku_name            = "P1v2"
  tags                = merge(local.common_tags)

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# Function App for David Driscoll
resource "azurerm_linux_function_app" "tc_function_app" {
  name                       = "salesforce-intsvc-${local.unique_stage}"
  location                   = data.azurerm_resource_group.rg_deployment.location
  resource_group_name        = data.azurerm_resource_group.rg_deployment.name
  service_plan_id            = azurerm_service_plan.appserviceplancontainer.id
  storage_account_name       = azurerm_storage_account.storage_account_tcfunction.name
  storage_account_access_key = azurerm_storage_account.storage_account_tcfunction.primary_access_key
  enabled                    = "true"
  https_only                 = "true"
  virtual_network_subnet_id  = data.azurerm_subnet.tc_function_subnet.id
  #key_vault_reference_identity_id = "SystemAssigned"

  app_settings = {
    ACCOUNT                                         = "${var.service_account}"
    APPINSIGHTS_INSTRUMENTATIONKEY                  = azurerm_application_insights.ai_salesforce_apim.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING           = azurerm_application_insights.ai_salesforce_apim.connection_string
    AzureWebJobsStorage                             = "${azurerm_storage_account.storage_account_tcfunction.primary_connection_string}"
    DOCKER_REGISTRY_SERVER_URL                      = "${var.acr_registry_server_url}"
    FUNCTIONS_EXTENSION_VERSION                     = "~3"
    #CONTAINER_NAME                                  = azurerm_storage_container.storage_hostkeycontainer_tcfunction.name
    KEYVAULT_SECRET                                 = "${var.keyvault_secret}"
    KEYVAULT_URL                                    = "${var.keyvault_url}"
    TRIALCARD__CONFIG__CAMPAIGNSERVICE              = "${var.config_campaignservice}"
    TRIALCARD__CONFIG__DOCUMENTSERVICE              = "${var.config_documentservice}"
    TRIALCARD__CONFIG__ESERVICESORCHESTRATORSERVICE = "${var.config_eservicesorchestratorservice}"
    TRIALCARD__DEFAULTPROGRAMID                     = "${var.defaultprogramid}"
    TRIALCARD__FALLBACKPROGRAMIDS__0                = "${var.fallbackprogramids_0}"
    TRIALCARD__OBFUSCATEDUSERID                     = "${var.obfuscateduserid}"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE             = "false"
    WEBSITE_USE_DIAGNOSTIC_SERVER                   = "true"
  }

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                               = "true"
    container_registry_use_managed_identity = "true"
    minimum_tls_version                     = "1.2"


    application_stack {
      docker {
        registry_url = var.acr_registry_server
        image_name   = var.acr_repo
        image_tag    = var.acr_image_tag
      }
    }

    app_service_logs {
      disk_quota_mb         = 35
      retention_period_days = 5
    }


    cors {
      allowed_origins     = ["https://portal.azure.com"]
      support_credentials = "false"
    }
    ftps_state                  = "FtpsOnly"
    http2_enabled               = "false"
    scm_use_main_ip_restriction = "false"
    vnet_route_all_enabled      = "true"
    websockets_enabled          = "false"
  }

  tags = merge(local.common_tags)

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

data "azurerm_function_app_host_keys" "tc_function_app_key" {
  name                = azurerm_linux_function_app.tc_function_app.name
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
}
