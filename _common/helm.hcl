terraform {
  source = "${local.private_modules_base_url}/${local.module_name}//?ref=${local.module_version}"
}

locals {
  module_name              = "k8s-helm"
  module_version           = "main"
  environment_vars         = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                      = local.environment_vars.locals.environment
  common_settings          = read_terragrunt_config("${get_repo_root()}/_common/common_settings.hcl")
  gitlab_token             = "${local.common_settings.locals.gitlab_token}"
  private_modules_base_url = "${local.common_settings.locals.private_modules_base_url}"
  namespace_vars           = read_terragrunt_config("../namespace.hcl")
  namespace                = "${local.namespace_vars.locals.namespace}"
}

inputs = {
  force_update            = true
  recreate_pods           = true
  helm_release_name       = "${basename(get_terragrunt_dir())}"
  helm_internal_repo_url  = "https://gitlab.com/api/v4/projects/40582099/packages/helm/stable"
  helm_internal_repo_user = "gitlab-ci-token"
  helm_internal_repo_pass = get_env("TF_HTTP_PASSWORD")
  k8s_namespace           = "${local.namespace}"
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

generate "provider_helm" {
  path      = "helm.generated.tf"
  if_exists = "overwrite"
  contents = <<EOF1
provider "helm" {
  experiments {
    manifest = true
  }
  kubernetes {
    host = "${dependency.k3s.outputs.public_lb_ip}:6443"
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
}
EOF1
}       
