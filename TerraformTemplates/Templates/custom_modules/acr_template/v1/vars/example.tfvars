service_name        = "mercalisqa" # Naming Configuration
location            = "centralus"  # Example: "eastus" | "centralus"
resource_group_name = "rg-acr-qa"  # Example: "rg-ai-qa"
acr_sku             = "Premium"
admin_enabled       = false
zone_redundancy_enabled = false                            # Example: false or true         # enable only for prod 
#georeplication_locations = ["eastus", "westus"]           # Example: ["eastus", "westus"]  # enable only for prod 