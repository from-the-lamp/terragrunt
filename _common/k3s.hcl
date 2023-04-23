terraform {
  source = "${local.private_modules_base_url}/${local.module_name}//?ref=${local.module_version}"
}

locals {
  module_name = "k3s-oci-cluster"
  module_version = "main"
  common_settings          = read_terragrunt_config("${get_repo_root()}/_common/common_settings.hcl")
  private_modules_base_url = "${local.common_settings.locals.private_modules_base_url}"
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
}

dependency "get_infra_variables" {
  config_path = "../gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    "map_variables.tenancy_ocid"     = "fake-tenancy-ocid"
    "map_variables.user_ocid"        = "fake-user-ocid"
    "map_variables.compartment_ocid" = "fake-compartment-ocid"
    "map_variables.fingerprint"      = "fake-fingerprint"
  }
}

inputs = {
  compartment_ocid          = "${dependency.get_infra_variables.outputs.map_variables.compartment_ocid}"
  k3s_load_balancer_name    = "k3s-internal"
  public_load_balancer_name = "k3s-public"
  k3s_server_pool_size      = 2
  k3s_worker_pool_size      = 2
  expose_kubeapi            = true
  my_public_ip_cidr         = "0.0.0.0/0"
  cluster_name              = "infra"
  os_image_id               = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaj6g2lci5ed7nfhk46olwkhmwkzrobyo3jntnhkk7fnm2vqflorna"
  availability_domain       = "Wxre:EU-FRANKFURT-1-AD-1"
  region                    = "eu-frankfurt-1"
  admin_ssh_pub             = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLA+49/73HHo5vMFTeurz8JdDsWza4WvJtN+WnSWi5i \n ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtNvLcjDTFxc/v03D93cyeEa77jxNC/u2DfqM9gn0k6"
  k3s_load_balancer_name    = "k3s-internal"
  public_load_balancer_name = "k3s-public"
  k3s_server_pool_size      = 2
  k3s_worker_pool_size      = 2
  expose_kubeapi            = true
  my_public_ip_cidr         = "0.0.0.0/0"
  cluster_name              = "infra"
  environment               = "${local.env}"
}

generate "oci_provider_cfg" {
  path      = "oci.generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
    provider "oci" {
      config_file_profile = "${get_env("AWS_PROFILE")}"
    }
  EOF
}
