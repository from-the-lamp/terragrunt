terraform {
  source = "${local.modules_url}/${local.module_name}//${local.module_dir}?ref=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  modules_url = local.common_settings.locals.private_modules_base_url
  module_name = "argocd"
  module_dir = "clusters"
  module_version = "main"
  infra_helm_repo_url = local.common_settings.locals.infra_helm_repo_url
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  infra_zone = local.environment_vars.locals.infra_zone
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  base_helm_chart_version = local.versions.locals.base_helm_chart
}

dependency "k8s_data_prod" {
  config_path = "${get_repo_root()}/prod/oracle/k3s/masters/ssh_read_file_content"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    file_contents = {
      "/etc/rancher/k3s/server-ip" = "ZmFrZS1kYXRhCg==",
      "/etc/rancher/k3s/server-certificate-authority-data" = "ZmFrZS1kYXRhCg==",
      "/etc/rancher/k3s/client-certificate-data" = "ZmFrZS1kYXRhCg==",
      "/etc/rancher/k3s/client-key-data" = "ZmFrZS1kYXRhCg==",
    }
  }
}

inputs = {
  server_addr = "argocd.from-the-lamp.work:443"
  auth_token = get_env("argo_auth_token")
  clusters = [
    {
      name = "prod"
      server = "https://${lookup(dependency.k8s_data_prod.outputs.file_contents, "/etc/rancher/k3s/server-ip")}:6443"
      ca_data = base64decode(lookup(dependency.k8s_data_prod.outputs.file_contents, "/etc/rancher/k3s/server-certificate-authority-data"))
      cert_data = base64decode(lookup(dependency.k8s_data_prod.outputs.file_contents, "/etc/rancher/k3s/client-certificate-data"))
      key_data = base64decode(lookup(dependency.k8s_data_prod.outputs.file_contents, "/etc/rancher/k3s/client-key-data"))
      insecure = false
    }
  ]
}
