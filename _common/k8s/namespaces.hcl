terraform {
  source = "${local.private_modules_base_url}/${local.module_name}//${local.module_subdir}?ref=${local.module_version}"
}

locals {
  module_name              = "k8s"
  module_subdir            = "namespaces"
  module_version           = "main"
  private_modules_base_url = local.common_settings.locals.private_modules_base_url
  environment_vars         = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                      = local.environment_vars.locals.environment
  common_settings          = read_terragrunt_config("${get_repo_root()}/_common/settings.hcl")
  gitlab_token             = local.common_settings.locals.gitlab_token
}

dependency "ssh_read_file_content" {
  config_path = "${get_repo_root()}/${local.env}/oracle/k3s/masters/ssh_read_file_content"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    file_contents = {}
  }
}

generate "provider_kubernetes" {
  path      = "kubernetes.generated.tf"
  if_exists = "overwrite"
  contents = <<EOF1
provider "kubernetes" {
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
EOF1
}

inputs = {
    helm_module_source = "${local.private_modules_base_url}/k8s/helm//?ref=main"
    namespaces = {
        "projects" = {
          labels = [
            {label="istio-injection", value="enabled"},
          ] 
        }
    }
}
