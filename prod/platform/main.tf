terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
      version = "4.96.0"
    }
  }

  backend "http" {
    address        = "https://gitlab.com/api/v4/projects/40541314/terraform/state/platform"
    lock_address   = "https://gitlab.com/api/v4/projects/40541314/terraform/state/platform/lock"
    unlock_address = "https://gitlab.com/api/v4/projects/40541314/terraform/state/platform/lock"
    username       = "gitlab-ci-token"
    lock_method    = "POST"
    unlock_method  = "DELETE"
  }
}

resource "local_file" "admin_id_rsa" {
    content  =  base64decode(var.admin_id_rsa_base64)
    filename = "/tmp/id_rsa"
}