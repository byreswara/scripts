variable "default_tags_enabled" {
  description = "Option to enable or disable default tags."
  type        = bool
  default     = true
}

variable "extra_tags" {
  description = "Additional tags to associate with your Network Security Group."
  type        = map(string)
  default     = {}
}

variable "deployer" {
  description = "Name of the deployer"
  type        = string
  default     = "default"
}

variable "ado_Project" {
  description = "Azure DevOps Project"
  type        = string
  default     = "default"
}

variable "ado_Repository" {
  description = "Azure DevOps Repository"
  type        = string
  default     = "default"
}

variable "ado_Branch" {
  description = "Azure DevOps Branch"
  type        = string
  default     = "default"
}
