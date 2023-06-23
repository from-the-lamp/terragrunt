terraform {
  source = "${local.private_modules_base_url}/${local.module_name}//?ref=${local.module_version}"
}

locals {
  module_name              = "k3s-oci-cluster"
  module_version           = "main"
  common_settings          = read_terragrunt_config("${get_repo_root()}/_common/settings.hcl")
  private_modules_base_url = local.common_settings.locals.private_modules_base_url
  compartment_ocid         = local.common_settings.locals.compartment_ocid
  k3s_os_image_id          = local.common_settings.locals.k3s_os_image_id
  k3s_admin_ssh_pub        = local.common_settings.locals.k3s_admin_ssh_pub
  k3s_availability_domain  = local.common_settings.locals.k3s_availability_domain
  k3s_region               = local.common_settings.locals.k3s_region
  environment_vars         = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                      = local.environment_vars.locals.environment
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
  compartment_ocid          = local.compartment_ocid
  k3s_load_balancer_name    = "k3s-internal"
  public_load_balancer_name = "k3s-public"
  k3s_server_pool_size      = 2
  k3s_worker_pool_size      = 2
  expose_kubeapi            = true
  my_public_ip_cidr         = "0.0.0.0/0"
  cluster_name              = "infra"
  os_image_id               = local.k3s_os_image_id
  availability_domain       = local.k3s_availability_domain
  region                    = local.k3s_region
  admin_ssh_pub             = local.k3s_admin_ssh_pub
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
