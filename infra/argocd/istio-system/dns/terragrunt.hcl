include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
}

dependency "gitlab_vars" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    variables = {
      cloudflare_api_token = "fake-token"
    }
  }
}

dependency "ingressgateway" {
  config_path = "../ingressgateway"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

inputs = {
  project = "infra"
  helm_chart_name = "crossplane-workspaces"
  helm_chart_version = "0.0.18"
  apps = [
    {
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
