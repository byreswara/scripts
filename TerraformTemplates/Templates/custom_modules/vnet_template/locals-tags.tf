locals {
  default_tags = var.default_tags_enabled ? {
    deployer    = "terraform"
    location    = var.location
    environment = var.subscription
    CreatedDate = timestamp()
  } : {}
}
