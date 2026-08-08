provider "nomad" {
  address = var.nomad_address
  region  = var.nomad_region

  # For ACL-enabled clusters use NOMAD_TOKEN.
  # Do not put the ACL token in terraform.tfvars.
}
