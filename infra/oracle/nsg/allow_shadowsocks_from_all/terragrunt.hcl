include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/oracle/nsg.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
}

dependency "vcn" {
  config_path                             = "${get_repo_root()}/${local.env}/oracle/vcn"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    vcn_id = "fake-id"
  }
}

inputs = {
  vcn_id        = dependency.vcn.outputs.vcn_id
  display_name  = "shadowsocks"
  tcp_rules = {
    default = {
      destination_port_range = {
        max = "1234"
        min = "1234"
      }
    }
  }
}
