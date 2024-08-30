service_name        = "mercalisbaseline" # Naming Configuration
location            = "centralus"        # Example: "eastus" | "centralus"
resource_group_name = "rg-acr-prod"      # Example: "rg-ai-qa"
acr_sku             = "Premium"
admin_enabled       = false

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
  },
  
  # group: sg.IT.devs.AZMig.eng.devops.ctr
  { 
    object_id = "00563e91-667a-4eed-b6e4-5e4658c8fbcf"
    role      = "AcrPull"
  },
]
