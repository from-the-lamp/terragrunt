include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  vault_base_url = local.common_settings.locals.vault_base_url
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  crossplane_workspaces_version = local.versions.locals.crossplane_workspaces
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
  apps = [
    {
      helm_chart_name = "crossplane-workspaces"
      helm_chart_version = local.crossplane_workspaces_version
      values = <<EOT
      workspaces:
        vault:
          enabled: true
          dir: kubernetes_engine
          vars:
          - key: kubernetes_host
            value: "https://${lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/server-ip")}:6443"
          - key: kubernetes_ca_cert
            value: ${base64decode(lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/server-certificate-authority-data"))}
      providers:
        vault:
          enabled: true
      EOT
    }
  ]
}
