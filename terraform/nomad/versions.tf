terraform {
  required_version = ">= 1.15.0, < 2.0.0"

  required_providers {
    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 2.6"
    }
  }
}
