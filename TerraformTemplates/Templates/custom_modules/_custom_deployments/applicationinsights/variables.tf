# Variable supplied from ADO default pipeline variable $(system.teamproject)
variable "project_name" {
  type        = string
  description = "The name of the project being deployed"
}

variable "location" {
  type        = string
  default     = "centralus"
  description = "The location for all resources"
}

# The following variables should be supplied via Azure Devops pipeline variables or variable libraries

variable "environment_name" {
    type = string
    default = "qa"
    description = "The deployments environment name"
}

variable "ai_rg" {
    type = string
    description = "The resource group hosting the ai instance"
}

variable "ai_name" {
    type = string
    description = "The name of the application insights resource"
}

variable "ai_alert" {
    type = string
    description = "The name of the application insights resource"
}

variable "alert_enabled" {
    type = bool
    default = true
    description = "Enable or disable the alert"
}

variable "workspace_name" {
    type = string
    description = "The name of the workspace that the application insights instance is tied to"
}

variable "subsriptionId" {
  type    = string
  default = "XXX"
}

variable "tenantId" {
  type = string
}

variable "dataCap" {
  type = number
  default = 1
  description = "value in GB for the daily data cap"
}