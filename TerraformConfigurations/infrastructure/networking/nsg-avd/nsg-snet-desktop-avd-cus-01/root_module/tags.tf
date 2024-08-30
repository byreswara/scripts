variable "deployer" {
  description = "The name of the person deploying the resources"
  type        = string
}

variable "ado_Project" {
  description = "The name of the Azure DevOps project"
  type        = string
}

variable "ado_Repository" {
  description = "The name of the Azure DevOps repository"
  type        = string
}

variable "ado_Branch" {
  description = "The name of the Azure DevOps repository branch"
  type        = string
}

variable "extra_tags" {
  description = "Additional tags to associate with your Network Security Group."
  type        = map(string)
  default     = {}
}