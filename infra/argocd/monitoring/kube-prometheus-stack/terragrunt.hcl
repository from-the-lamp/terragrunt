include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application.hcl"
}

locals {
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  kube_prometheus_stack_version = local.versions.locals.kube_prometheus_stack
  istio_gateway_version = local.versions.locals.istio_gateway
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  gitlab_base_url = local.common_settings.locals.gitlab_base_url
  grafana_openid_client_id = local.common_settings.locals.grafana_openid_client_id
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  infra_zone = local.environment_vars.locals.infra_zone
}

dependency "get_infra_variables" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    variables = {
      grafana_openid_client_secret = "fake-secret"
    }
  }
}

inputs = {
  project = "infra"
  ignore_difference = [
    {
      group = "cert-manager.io"
      kind = "Certificate"
      json_pointers = [
        "/spec/duration",
        "/spec/renewBefore"
      ]
      jq_path_expressions = []
    }
  ]
  apps = [
    {
      helm_repo_url = "https://prometheus-community.github.io/helm-charts"
      helm_chart_version = local.kube_prometheus_stack_version
      values = <<EOT
      grafana:
        grafana.ini:
          server:
            root_url: "https://grafana.${local.infra_zone}"
          auth.gitlab:
            enabled: true
            auto_login: true
            scopes: openid, email, profile
            client_id: "${local.grafana_openid_client_id}"
            client_secret: "${dependency.get_infra_variables.outputs.variables.grafana_openid_client_secret}"
            auth_url: "https://${local.gitlab_base_url}/oauth/authorize"
            token_url: "https://${local.gitlab_base_url}/oauth/token"
            api_url: "https://${local.gitlab_base_url}/api/v4"
            allowed_groups: "from-the-lamp"
            role_attribute_path: "contains(groups[*], 'from-the-lamp') && 'Admin' || 'Viewer'"
      EOT
    }
  ]
}
