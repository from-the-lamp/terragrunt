include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/cloudflare/record.hcl"
}

locals {
  environment_vars  = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env               = local.environment_vars.locals.environment
  group_vars        = read_terragrunt_config(find_in_parent_folders("group.hcl"))
  cloudflare_record = local.group_vars.locals.cloudflare_record
}

inputs = {
  cloudflare_record = local.cloudflare_record
}
