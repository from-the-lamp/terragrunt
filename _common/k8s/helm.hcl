terraform {
  source = "${local.private_modules_base_url}/${local.module_name}//${local.module_subdir}?ref=${local.module_version}"
}

locals {
  module_name              = "k8s"
  module_subdir            = "helm"
  module_version           = "main"
  private_modules_base_url = local.common_settings.locals.private_modules_base_url
  environment_vars         = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                      = local.environment_vars.locals.environment
  common_settings          = read_terragrunt_config("${get_repo_root()}/_common/settings.hcl")
  gitlab_token             = local.common_settings.locals.gitlab_token
}

inputs = {
  force_update            = true
  recreate_pods           = true
  helm_release_name       = basename(get_terragrunt_dir())
  helm_internal_repo_url  = "https://gitlab.com/api/v4/projects/40582099/packages/helm/stable"
  helm_internal_repo_user = "gitlab-ci-token"
  helm_internal_repo_pass = get_env("TF_HTTP_PASSWORD")
  helm_values_file_path   = "values.yml"
  k8s_namespace           = basename(dirname(get_terragrunt_dir()))
}

dependency "ssh_read_file_content" {
  config_path = "${get_repo_root()}/${local.env}/oracle/k3s/masters/ssh_read_file_content"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    file_contents = {}
  }
}

generate "provider_helm" {
  path      = "helm.generated.tf"
  if_exists = "overwrite"
  contents = <<EOF1
provider "helm" {
  // experiments {
  //   manifest = true
  // }
  kubernetes {
    host = "https://${lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/server")}:6443"
    cluster_ca_certificate = <<-EOF2
${base64decode(lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/certificate-authority-data"))}
    EOF2
    client_certificate = <<-EOF2
${base64decode(lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/client-certificate-data"))}
    EOF2
    client_key= <<-EOF2
${base64decode(lookup(dependency.ssh_read_file_content.outputs.file_contents, "/etc/rancher/k3s/client-key-data"))}
    EOF2
  }
}
EOF1
}       
