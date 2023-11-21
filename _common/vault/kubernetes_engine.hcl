terraform {
  source = "${local.modules_url}/${local.module_name}//${local.module_dir}?ref=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  modules_url = local.common_settings.locals.private_modules_base_url
  module_name = "vault"
  module_dir = "kubernetes_engine"
  module_version = "main"
  vault_base_url = local.common_settings.locals.vault_base_url
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
}

dependency "get_infra_variables" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    variables = {
      vault_token = "fake-token"
    }
  }
}

dependency "ssh_read_file_content" {
  config_path = "${get_repo_root()}/${local.env}/oracle/k3s/masters/ssh_read_file_content"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    file_contents = {
      "/etc/rancher/k3s/server-ip" = "ZmFrZS1kYXRhCg==",
      "/etc/rancher/k3s/server-certificate-authority-data" = "ZmFrZS1kYXRhCg==",
      "/etc/rancher/k3s/client-certificate-data" = "ZmFrZS1kYXRhCg==",
    }
  }
}

inputs = {
  host = "https://${local.vault_base_url}"
  token = dependency.get_infra_variables.outputs.variables.vault_token
  kubernetes_host = "https://${lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/server-ip")}:6443"
  kubernetes_ca_cert = <<-EOF
${base64decode(lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/server-certificate-authority-data"))}
    EOF
}
