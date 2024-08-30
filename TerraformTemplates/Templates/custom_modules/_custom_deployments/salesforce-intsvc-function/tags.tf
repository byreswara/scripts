locals {
  common_tags = {
    deployer    = "terraform"
    environment = "${local.unique_stage}"
    location    = "${var.location}"
    project     = "${var.project_name}"
    CreatedDate = timestamp()
  }
}
