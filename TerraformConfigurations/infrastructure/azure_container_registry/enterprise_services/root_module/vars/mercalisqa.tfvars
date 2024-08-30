service_name        = "mercalisqa" # Naming Configuration
location            = "centralus"  # Example: "eastus" | "centralus"
resource_group_name = "rg-acr-qa"  # Example: "rg-ai-qa"
acr_sku             = "Premium"
admin_enabled       = false
zone_redundancy_enabled = false                            # Example: false or true         # enable only for prod 
#georeplication_locations = ["eastus"]           # Example: ["eastus", "westus"]  # enable only for prod 

# RBAC Variables:
iam_policies = [
  # group: tm.devops
  {
    object_id = "f2cfb948-4d54-46de-bf70-a12b444cf6b2"
    role      = "Contributor"
  },
  {
    object_id = "f2cfb948-4d54-46de-bf70-a12b444cf6b2"
    role      = "AcrPull"
  },
  {
    object_id = "f2cfb948-4d54-46de-bf70-a12b444cf6b2"
    role      = "AcrPush"
  },
  # group: tm.architecture
  {
    object_id = "2ff3d676-1016-4766-9d24-10ce51630c53"
    role      = "Contributor"
  },
  {
    object_id = "2ff3d676-1016-4766-9d24-10ce51630c53"
    role      = "AcrPull"
  },
  {
    object_id = "2ff3d676-1016-4766-9d24-10ce51630c53"
    role      = "AcrPush"
  }
]
