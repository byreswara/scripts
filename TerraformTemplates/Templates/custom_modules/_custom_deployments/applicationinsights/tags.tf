locals {
  common_tags = {
    deployer    = "terraform"
    environment = "${local.environment_name}"
    location    = "${local.location}"
    project     = "${local.project_name}"
    CreationDate = timestamp()
  }
}
