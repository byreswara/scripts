# >>>> INBUILT
variable "stage_mapping" {
  type = map(object({
    unique_stage : string
    shared_stage : string
  }))
  default = {
    "dv" : {
      unique_stage : "dv"
      shared_stage : "nonprod"
    },
    "dev" : {
      unique_stage : "dev"
      shared_stage : "nonprod"
    },
    "qa" : {
      unique_stage : "qa"
      shared_stage : "nonprod"
    },
    "uat" : {
      unique_stage : "uat"
      shared_stage : "nonprod"
    },
    "sit" : {
      unique_stage : "sit"
      shared_stage : "nonprod"
    },
    "prod" : {
      unique_stage : "prod"
      shared_stage : "prod"
    }
  }
}

variable "location_mapping" {
  type = map(object({
    short_name : string
    long_name : string
  }))
  default = {
    "westeurope" : {
      short_name : "weu"
      long_name : "westeurope"
    },
    "centralus" : {
      short_name : "cus"
      long_name : "centralus"
    }
  }
}


variable "location" {
  type        = string
  default     = "centralus"
  description = "The location for all resources"
}

variable "stage" {
  type        = string
  default     = "dev"
  description = "The stage"
}

variable "project_name" {
  type        = string
  default     = "TrialCardAPIM"
  description = "The name of the project being deployed"
}

variable "project_name_alnum" {
  type        = string
  default     = "trialcardapim"
  description = "The alpha numeric only name of the project being deployed"
}

variable "subsriptionId" {
  type    = string
  default = "XXX"
}

# variable "appId" {
#   type = string
# }

# variable "appSecret" {
#   type = string
# }

variable "tenantId" {
  type = string
}

# Trialcard Variables:

variable "acr_repo" {
  type    = string
  default = "tcsalesforce.intsvc"
}

variable "acr_image_tag" {
  type    = string
  default = "latest"
}

variable "acr_registry_server_url" {
  type    = string
  default = "https://trialcard.azurecr.io"
}

variable "acr_registry_server" {
  type    = string
  default = "trialcard.azurecr.io"
}

variable "config_campaignservice" {
  type = string
}
variable "config_documentservice" {
  type = string
}
variable "config_eservicesorchestratorservice" {
  type = string
}
variable "defaultprogramid" {
  type = string
}
variable "fallbackprogramids_0" {
  type = string
}
variable "obfuscateduserid" {
  type = string
}
variable "keyvault_secret" {
  type = string
}
variable "keyvault_url" {
  type = string
}
variable "appinsights_instrumentationkey" {
  type = string
}
variable "appinsights_connectionstring" {
  type = string
}

variable "backend_eservicesorchestrator" {
  type = string
}

variable "backend_apigateway" {
  type = string
}

variable "auth0DefaultClientId" {
  type = string
}

variable "auth0DefaultClientSecret" {
  type = string
}

variable "auth0AuthorizationServer" {
  type = string
}

variable "eservicesOrchestratorAudience" {
  type = string
}

variable "eservicesOrchestratorProgramid" {
  type = string
}

variable "service_account" {
  type = string
}