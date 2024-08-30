service_name        = "nsg-snet-citiustech-avd-cus-01" # Naming Configuration
location            = "centralus" # Example: "eastus" | "centralus"
resource_group_name = "rg-avd-core-cus-01" # Example: "rg-ai-qa"
extra_tags          = {} # Example: { "tag" = "value" }

additional_rules = [
  # Inbound Rules
  {
    priority  = 100
    name      = "Allow_ICMP_10.0.0.0_s8_In"
    direction = "Inbound"
    access    = "Allow"
    protocol  = "Icmp"

    source_port_range      = "*"
    destination_port_range = "*"

    source_address_prefix      = "10.0.0.0/8"
    destination_address_prefix = "*"
  },
  {
    priority  = 1000
    name      = "AllowTag_EntraID_TCP_In"
    direction = "Inbound"
    access    = "Allow"
    protocol  = "Tcp"

    source_port_range       = "*"
    destination_port_ranges = ["123", "137", "135", "138", "139", "389", "445", "464", "636", "1025-5000", "5722", "9389", "49152-65535"]

    source_address_prefix      = "AzureActiveDirectory"
    destination_address_prefix = "*"
  },
  {
    priority  = 1010
    name      = "AllowTag_EntraID_UDP_In"
    direction = "Inbound"
    access    = "Allow"
    protocol  = "Udp"

    source_port_range       = "*"
    destination_port_ranges = ["88", "123", "137", "138", "139", "389", "445", "464", "636", "2535"]

    source_address_prefix      = "AzureActiveDirectory"
    destination_address_prefix = "*"
  },
  {
    priority  = 1100
    name      = "AllowTag_EntraID-DS_TCP_In"
    direction = "Inbound"
    access    = "Allow"
    protocol  = "Tcp"

    source_port_range       = "*"
    destination_port_ranges = ["123", "137", "135", "138", "139", "389", "445", "464", "636", "1025-5000", "5722", "9389", "49152-65535"]

    source_address_prefix      = "AzureActiveDirectoryDomainServices"
    destination_address_prefix = "*"
  },
  {
    priority  = 1110
    name      = "AllowTag_EntraID-DS_UDP_In"
    direction = "Inbound"
    access    = "Allow"
    protocol  = "Udp"

    source_port_range       = "*"
    destination_port_ranges = ["88", "123", "137", "138", "139", "389", "445", "464", "636", "2535"]

    source_address_prefix      = "AzureActiveDirectoryDomainServices"
    destination_address_prefix = "*"
  },
  # Outbound Rules
  {
    priority  = 100
    name      = "Allow_ICMP_10.0.0.0_s8_Out"
    direction = "Outbound"
    access    = "Allow"
    protocol  = "Icmp"

    source_port_range      = "*"
    destination_port_range = "*"

    source_address_prefix      = "*"
    destination_address_prefix = "10.0.0.0/8"
  },
  {
    priority  = 1000
    name      = "AllowTag_EntraID_TCP_Out"
    direction = "Outbound"
    access    = "Allow"
    protocol  = "Tcp"

    source_port_range       = "*"
    destination_port_ranges = ["123", "137", "135", "138", "139", "389", "445", "464", "636", "1025-5000", "5722", "9389", "49152-65535"]

    source_address_prefix      = "*"
    destination_address_prefix = "AzureActiveDirectory"
  },
  {
    priority  = 1010
    name      = "AllowTag_EntraID_UDP_Out"
    direction = "Outbound"
    access    = "Allow"
    protocol  = "Udp"

    source_port_range       = "*"
    destination_port_ranges = ["88", "123", "137", "138", "139", "389", "445", "464", "636", "2535"]

    source_address_prefix      = "*"
    destination_address_prefix = "AzureActiveDirectory"
  },
  {
    priority  = 1100
    name      = "AllowTag_EntraID-DS_TCP_Out"
    direction = "Outbound"
    access    = "Allow"
    protocol  = "Tcp"

    source_port_range       = "*"
    destination_port_ranges = ["123", "137", "135", "138", "139", "389", "445", "464", "636", "1025-5000", "5722", "9389", "49152-65535"]

    source_address_prefix      = "*"
    destination_address_prefix = "AzureActiveDirectoryDomainServices"
  },
  {
    priority  = 1110
    name      = "AllowTag_EntraID-DS_UDP_Out"
    direction = "Outbound"
    access    = "Allow"
    protocol  = "Udp"

    source_port_range       = "*"
    destination_port_ranges = ["88", "123", "137", "138", "139", "389", "445", "464", "636", "2535"]

    source_address_prefix      = "*"
    destination_address_prefix = "AzureActiveDirectoryDomainServices"
  }
]