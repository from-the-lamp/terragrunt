remote_state {
  backend = "http"
  config = {
    address        = "https://gitlab.com/api/v4/projects/40541314/terraform/state/prod"
    lock_address   = "https://gitlab.com/api/v4/projects/40541314/terraform/state/prod/lock"
    unlock_address = "https://gitlab.com/api/v4/projects/40541314/terraform/state/prod/lock"
    username       = "gitlab-ci-token"
    lock_method    = "POST"
    unlock_method  = "DELETE"
  }
}

locals {
  default_yaml_path = "../defaults.yml"
}

inputs = merge(
  yamldecode(
    file("${get_terragrunt_dir()}/${find_in_parent_folders("values.yml", local.default_yaml_path)}"),
  ),
  {
    environment               = "prod"
    tenancy_ocid              = "${get_env("TF_VAR_tenancy_ocid")}"
    compartment_ocid          = "${get_env("TF_VAR_compartment_ocid")}"
    availability_domain       = "Wxre:EU-FRANKFURT-1-AD-1"
    region                    = "eu-frankfurt-1"
    admin_ssh_pub             = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLA+49/73HHo5vMFTeurz8JdDsWza4WvJtN+WnSWi5i \n ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtNvLcjDTFxc/v03D93cyeEa77jxNC/u2DfqM9gn0k6"
  },
)

generate "terraform" {
  path      = "terraform.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
    terraform {
      backend "http" {}
      required_providers {
        oci = {
          source  = "oracle/oci"
          version = "4.102.0"
        }
      }
    }
  EOF
}
