terraform {
  source = "${local.private_modules_base_url}/${local.module_name}//?ref=${local.module_version}"
}

locals {
  module_name              = "k8s-namespaces"
  module_version           = "main"
  environment_vars         = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                      = "${local.environment_vars.locals.environment}"
  common_settings          = read_terragrunt_config("${get_repo_root()}/_common/common_settings.hcl")
  gitlab_token             = "${local.common_settings.locals.gitlab_token}"
  private_modules_base_url = "${local.common_settings.locals.private_modules_base_url}"
}

dependency "k3s" {
  config_path = "${get_repo_root()}/${local.env}/k3s"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    public_lb_ip                       = "1.2.3.4"
    cluster_certificate_authority_data = "ZmFrZS1kYXRhCg=="
    client_certificate_data            = "ZmFrZS1kYXRhCg=="
    client_key_data                    = "ZmFrZS1kYXRhCg=="
  }
}

generate "provider_kubernetes" {
  path      = "kubernetes.generated.tf"
  if_exists = "overwrite"
  contents = <<EOF1
provider "kubernetes" {
    host = "https://${dependency.k3s.outputs.public_lb_ip}:6443"
    cluster_ca_certificate = <<-EOF2
${base64decode(dependency.k3s.outputs.cluster_certificate_authority_data)}
    EOF2
    client_certificate = <<-EOF2
${base64decode(dependency.k3s.outputs.client_certificate_data)}
    EOF2
    client_key= <<-EOF2
${base64decode(dependency.k3s.outputs.client_key_data)}
    EOF2
}
EOF1
}

inputs = {
    namespaces = {
        "projects" = {
          labels = [
            {label="istio-injection", value="enabled"},
          ] 
        }
    }
}
