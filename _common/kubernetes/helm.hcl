terraform {
  source = "${local.modules_url}//${local.module_dir}?ref=${local.module_version}"
}

locals {
  common_settings     = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  modules_url         = local.common_settings.locals.private_modules_base_url
  module_dir          = "kubernetes/helm"
  module_version      = "main"
  infra_helm_repo_url = "oci://registry.gitlab.com/from-the-lamp/infra/helm-charts"
  environment_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                 = local.environment_vars.locals.environment
}

dependency "ssh_read_file_content" {
  config_path                             = "${get_repo_root()}/${local.env}/oracle/k3s/masters/ssh_read_file_content"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    file_contents = {
      "/etc/rancher/k3s/server-ip"                         = "ZmFrZS1kYXRhCg==",
      "/etc/rancher/k3s/server-certificate-authority-data" = "ZmFrZS1kYXRhCg==",
      "/etc/rancher/k3s/client-certificate-data"           = "ZmFrZS1kYXRhCg==",
      "/etc/rancher/k3s/client-key-data"                   = "ZmFrZS1kYXRhCg==",
    }
  }
}

inputs = {
  kubernetes_host                   = "https://${lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/server-ip")}:6443"
  kubernetes_cluster_ca_certificate = <<-EOF
${base64decode(lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/server-certificate-authority-data"))}
    EOF
  kubernetes_client_certificate     = <<-EOF
${base64decode(lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/client-certificate-data"))}
    EOF
  kubernetes_client_key             = <<-EOF
${base64decode(lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/client-key-data"))}
    EOF
  helm_force_update                 = true
  helm_recreate_pods                = true
  helm_repo_url                     = local.infra_helm_repo_url
  helm_chart_name                   = basename(get_terragrunt_dir())
  helm_release_name                 = basename(get_terragrunt_dir())
  helm_values_file                  = "values.yml"
  helm_namespace                    = basename(dirname(get_terragrunt_dir()))
  helm_create_namespace             = true
}
