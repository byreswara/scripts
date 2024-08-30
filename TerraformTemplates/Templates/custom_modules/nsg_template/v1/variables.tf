variable "location" {
  description = "Azure location."
  type        = string
}

variable "nsg_name" {
  description = "Network security group name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "deny_all_inbound" {
  description = "True to deny all inbound traffic by default"
  type        = bool
  default     = false
}

variable "deny_all_inbound_priority" {
  description = "Priority for deny_all_inbound rule"
  type        = number
  default     = 4096
}

variable "http_inbound_allowed" {
  description = "True to allow inbound HTTP traffic"
  type        = bool
  default     = false
}

variable "allowed_http_source" {
  description = "Allowed source for inbound HTTP traffic. Can be a Service Tag, \"*\" or a CIDR list."
  type        = any
  default     = []
  validation {
    condition = (
      var.allowed_http_source != null &&
      var.allowed_http_source != "" &&
      (can(tolist(var.allowed_http_source)) || can(tostring(var.allowed_http_source)))
    )
    error_message = "Variable must be a Service Tag, \"*\" or a list of CIDR."
  }
}

variable "http_inbound_priority" {
  description = "Priority for HTTP inbound rule"
  type        = number
  default     = 4000
}

variable "https_inbound_allowed" {
  description = "True to allow inbound HTTPS traffic"
  type        = bool
  default     = false
}

variable "allowed_https_source" {
  description = "Allowed source for inbound HTTPS traffic. Can be a Service Tag, \"*\" or a CIDR list."
  type        = any
  default     = []
  validation {
    condition = (
      var.allowed_https_source != null &&
      var.allowed_https_source != "" &&
      (can(tolist(var.allowed_https_source)) || can(tostring(var.allowed_https_source)))
    )
    error_message = "Variable must be a Service Tag, \"*\" or a list of CIDR."
  }
}

variable "https_inbound_priority" {
  description = "Priority for HTTPS inbound rule"
  type        = number
  default     = 4001
}

variable "ssh_inbound_allowed" {
  description = "True to allow inbound SSH traffic"
  type        = bool
  default     = false
}

variable "allowed_ssh_source" {
  description = "Allowed source for inbound SSH traffic. Can be a Service Tag, \"*\" or a CIDR list."
  type        = any
  default     = []
  validation {
    condition = (
      var.allowed_ssh_source != null &&
      var.allowed_ssh_source != "" &&
      (can(tolist(var.allowed_ssh_source)) || can(tostring(var.allowed_ssh_source)))
    )
    error_message = "Variable must be a Service Tag, \"*\" or a list of CIDR."
  }
}

variable "ssh_inbound_priority" {
  description = "Priority for ssh inbound rule"
  type        = number
  default     = 4002
}

variable "rdp_inbound_allowed" {
  description = "True to allow inbound RDP traffic"
  type        = bool
  default     = false
}

variable "allowed_rdp_source" {
  description = "Allowed source for inbound RDP traffic. Can be a Service Tag, \"*\" or a CIDR list."
  type        = any
  default     = []
  validation {
    condition = (
      var.allowed_rdp_source != null &&
      var.allowed_rdp_source != "" &&
      (can(tolist(var.allowed_rdp_source)) || can(tostring(var.allowed_rdp_source)))
    )
    error_message = "Variable must be a Service Tag, \"*\" or a list of CIDR."
  }
}

variable "rdp_inbound_priority" {
  description = "Priority for RDP inbound rule"
  type        = number
  default     = 4003
}

variable "winrm_inbound_allowed" {
  description = "True to allow inbound WinRM traffic"
  type        = bool
  default     = false
}

variable "allowed_winrm_source" {
  description = "Allowed source for inbound WinRM traffic. Can be a Service Tag, \"*\" or a CIDR list."
  type        = any
  default     = []
  validation {
    condition = (
      var.allowed_winrm_source != null &&
      var.allowed_winrm_source != "" &&
      (can(tolist(var.allowed_winrm_source)) || can(tostring(var.allowed_winrm_source)))
    )
    error_message = "Variable must be a Service Tag, \"*\" or a list of CIDR."
  }
}

variable "winrm_inbound_priority" {
  description = "Priority for WinRM inbound rule"
  type        = number
  default     = 4004
}

variable "application_gateway_rules_enabled" {
  description = "True to configure rules mandatory for hosting an Application Gateway. See https://docs.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure#allow-access-to-a-few-source-ips"
  type        = bool
  default     = false
}

variable "application_gateway_rules_priority" {
  description = "Priority for Application Gateway rules"
  type        = number
  default     = 4005
}

variable "load_balancer_rules_enabled" {
  description = "True to configure rules mandatory for hosting a Load Balancer."
  type        = bool
  default     = false
}

variable "load_balancer_rules_priority" {
  description = "Priority for Load Balancer rules"
  type        = number
  default     = 4006
}


variable "nfs_inbound_allowed" {
  description = "True to allow inbound NFSv4 traffic"
  type        = bool
  default     = false
}

variable "allowed_nfs_source" {
  description = "Allowed source for inbound NFSv4 traffic. Can be a Service Tag, \"*\" or a CIDR list."
  type        = any
  default     = []
  validation {
    condition = (
      var.allowed_nfs_source != null &&
      var.allowed_nfs_source != "" &&
      (can(tolist(var.allowed_nfs_source)) || can(tostring(var.allowed_nfs_source)))
    )
    error_message = "Variable must be a Service Tag, \"*\" or a list of CIDR."
  }
}

variable "nfs_inbound_priority" {
  description = "Priority for NFSv4 inbound rule"
  type        = number
  default     = 4007
}

variable "cifs_inbound_allowed" {
  description = "True to allow inbound CIFS traffic"
  type        = bool
  default     = false
}

variable "allowed_cifs_source" {
  description = "Allowed source for inbound CIFS traffic. Can be a Service Tag, \"*\" or a CIDR list."
  type        = any
  default     = []
  validation {
    condition = (
      var.allowed_cifs_source != null &&
      var.allowed_cifs_source != "" &&
      (can(tolist(var.allowed_cifs_source)) || can(tostring(var.allowed_cifs_source)))
    )
    error_message = "Variable must be a Service Tag, \"*\" or a list of CIDR."
  }
}

variable "cifs_inbound_priority" {
  description = "Priority for CIFS inbound rule"
  type        = number
  default     = 4008
}

variable "additional_rules" {
  description = "Additional network security group rules to add. For arguements please refer to https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule#argument-reference"
  type = list(object({
    priority  = number
    name      = string
    direction = optional(string, "Inbound")
    access    = optional(string, "Allow")
    protocol  = optional(string, "Tcp")

    source_port_range  = optional(string)
    source_port_ranges = optional(list(string))

    destination_port_range  = optional(string)
    destination_port_ranges = optional(list(string))

    source_address_prefix   = optional(string)
    source_address_prefixes = optional(list(string))

    destination_address_prefix   = optional(string)
    destination_address_prefixes = optional(list(string))
  }))
  default = []
}