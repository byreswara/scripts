# snet-<App / Service name>-<subscription>-<##>
subnet_name                   = "snet-test-qa-01-tfexample"
location_short                = "cus"
environment                   = "qa"
resource_group_name           = "rg-terratesting-qa"
virtual_network_name          = "vnet-qa-cus-01"
subnet_cidr_list              = ["10.82.11.0/24"]
route_table_name              = null #"rt-test"
route_table_rg                = null #"rg-terratesting-qa"
network_security_group_name   = "nsg-snet-test-qa-01"
network_security_group_rg     = "rg-terratesting-qa"
service_endpoints             = null # example: ["Microsoft.AzureActiveDirectory", "Microsoft.AzureCosmosDB"]
service_endpoint_policy_ids   = null #[]
private_link_endpoint_enabled = null
private_link_service_enabled  = null
subnet_delegation = {}
#   "Microsoft.Web/serverFarms" = [
#     {
#       name    = "Microsoft.Web/serverFarms"
#       actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
#     }
#   ]
# }