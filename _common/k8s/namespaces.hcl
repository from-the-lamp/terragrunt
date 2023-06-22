terraform {
  source = "${local.private_modules_base_url}/${local.module_name}//${local.module_subdir}?ref=${local.module_version}"
}

locals {
  module_name              = "k8s"
  module_subdir            = "namespaces"
  module_version           = "main"
  private_modules_base_url = "${local.common_settings.locals.private_modules_base_url}"
  environment_vars         = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                      = "${local.environment_vars.locals.environment}"
  common_settings          = read_terragrunt_config("${get_repo_root()}/_common/settings.hcl")
  gitlab_token             = "${local.common_settings.locals.gitlab_token}"
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

dependency "get_infra_variables" {
  config_path =  "${get_repo_root()}/${local.env}/gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    "map_variables.gitlab_docker_registry_token" = "fake-secret"
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
    helm_module_source = "${local.private_modules_base_url}/k8s/helm//?ref=main"
    namespaces = {
        "projects" = {
          labels = [
            {label="istio-injection", value="enabled"},
          ] 
        }
    }
    charts = [
      {
        helm_internal_repo      = true
        helm_chart_name         = "image-pull-secrets"
        helm_chart_version      = "0.0.1"
        force_update            = true
        helm_release_name       = "image-pull-secrets"
        helm_internal_repo_url  = "https://gitlab.com/api/v4/projects/40582099/packages/helm/stable"
        helm_internal_repo_user = "gitlab-ci-token"
        helm_internal_repo_pass = get_env("TF_HTTP_PASSWORD")
        helm_addition_setting   = {
          "base64DockerConfigs.gitlab-docker-registry" = dependency.get_infra_variables.outputs.map_variables.gitlab_docker_registry_token
        }
      }
    ]
}
