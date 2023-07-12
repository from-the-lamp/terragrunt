include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/gitlab/add_variables.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
}

dependency "ssh_read_file_content" {
  config_path = "${get_repo_root()}/${local.env}/oracle/k3s/masters/ssh_read_file_content"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    file_contents = {}
  }
}

inputs = {
  vars = {
    "${local.env}_KUBECONFIG_BASE64" = {
      value     = "${base64encode(lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/k3s.yaml"))}"
      protected = false
      masked    = true
    },
  }
}
