include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/cloudinit_config.hcl"
}

locals {
  environment_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                 = local.environment_vars.locals.environment
  common_settings     = read_terragrunt_config("${get_repo_root()}/_common/settings.hcl")
  compartment_ocid    = local.common_settings.locals.compartment_ocid
  availability_domain = local.common_settings.locals.availability_domain
  k3s_version         = local.common_settings.locals.k3s_version
}

dependency "token" {
  config_path =  "${get_repo_root()}/${local.env}/oracle/k3s/token"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    "password" = "fake-password"
  }
}

dependency "get_infra_variables" {
  config_path =  "${get_repo_root()}/${local.env}/gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    "map_variables.k3s_master_host" = "fake-host"
  }
}

inputs = {
  content = "${get_repo_root()}/_common/oracle/scripts/k3s.sh"
  vars    = {
    compartment_ocid    = local.compartment_ocid
    availability_domain = local.availability_domain
    k3s_version         = local.k3s_version
    k3s_master_host     = dependency.get_infra_variables.outputs.map_variables.k3s_master_host
    k3s_token           = dependency.token.outputs.password
  }
}
