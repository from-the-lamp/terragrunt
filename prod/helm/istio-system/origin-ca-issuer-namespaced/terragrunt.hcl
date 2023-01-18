include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/helm.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = "${local.environment_vars.locals.environment}"
}

dependency "origin-ca-issuer" {
  config_path  = "../origin-ca-issuer"
  skip_outputs = true
}

inputs = {
  helm_local_repo       = true
  helm_addition_setting = {
    originCAissuerKey   = "${get_env("TF_VAR_originCAissuerKey")}"
  }
}
