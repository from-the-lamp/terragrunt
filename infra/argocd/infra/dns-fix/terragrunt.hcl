include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  crossplane_workspaces_version = local.versions.locals.crossplane_workspaces
  helm_repo_url = local.common_settings.locals.infra_helm_repo_url
  helm_repo_user = local.common_settings.locals.helm_repo_user
  helm_repo_pass = local.common_settings.locals.helm_repo_pass
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
}

dependency "gitlab_vars" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    variables = {
      cloudflare_api_token = "fake-token"
    }
  }
}

inputs = {
  dest_cluster_list = [
    {
      cluster = "in-cluster"
      domen = "from-the-lamp.com"
    }
  ]
  apps = [
    {
      helm_chart_name = "crossplane-workspaces"
      helm_chart_version = local.crossplane_workspaces_version
      values = <<EOT
      workspaces:
        cloudflare:
          enabled: true
          url: https://gitlab.com/from-the-lamp/infra/terraform/modules/cloudflare
          dir: dns_record
          branch: main
          varmap:
            cloudflare-records:
            - name: "."
              type: A
              proxied: true
            - name: "*"
              type: A
              proxied: true
          vars:
          - key: external_load_balancer
            value: "true"
          - key: internal_load_balancer
            value: "false"
          - key: external_lb_svc_namespace
            value: "istio-system"
          - key: external_lb_svc_name
            value: "ingressgateway"
          - key: cloudflare_api_token
            value: ${dependency.gitlab_vars.outputs.variables.cloudflare_api_token}
          - key: cloudflare_zone_name
            value: "{{domen}}"
      providers:
        cloudflare:
          enabled: true
      EOT
    }
  ]
}
