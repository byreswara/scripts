variable "location_short" {
  description = "Short string for Azure location."
  type        = string
}

variable "environment" {
  description = "Project environment"
  type        = string
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
  default     = ""
}

variable "subnet_cidr_list" {
  description = "The address prefix list to use for the subnet."
  type        = list(string)
}

variable "route_table_name" {
  description = "The Route Table name to associate with the subnet."
  type        = string
  default     = null
}

variable "service_endpoints" {
  description = "The list of Service endpoints to associate with the subnet."
  type        = list(string)
  default     = []
}

variable "service_endpoint_policy_ids" {
  description = "The list of IDs of Service Endpoint Policies to associate with the subnet."
  type        = list(string)
  default     = null
}

variable "private_link_endpoint_enabled" {
  description = "Enable or disable network policies for the Private Endpoint on the subnet."
  type        = bool
  default     = null
}

variable "subnet_delegation" {
  description = <<EOD
Configuration delegations on subnet
object({
  name = object({
    name = string,
    actions = list(string)
  })
})
EOD
  type        = map(list(any))
  default     = {}
}

variable "route_table_id" {
  description = "The list of network_security_group_id to associate with the subnet."
  type        = string
  default     = null
}


