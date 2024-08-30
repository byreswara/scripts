locals {
  access_policies = flatten([
    for object_id, access_policy in var.access_policies : [{
      object_id               = access_policy.object_id
      key_permissions         = access_policy.key_permissions
      secret_permissions      = access_policy.secret_permissions
      certificate_permissions = access_policy.certificate_permissions
      storage_permissions     = access_policy.storage_permissions
    }]
  ])
}
