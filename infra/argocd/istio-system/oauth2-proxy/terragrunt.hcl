include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  openid_client_id_oauth2_proxy = local.common_settings.locals.openid_client_id_oauth2_proxy
}

dependency "infra_variables" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    variables = {
      openid_client_secret_oauth2_proxy = "fake-secret"
    }
  }
}

inputs = {
  project = "infra"
  dest_cluster_list = [
    {
      cluster = "prod-0"
      domen = "from-the-lamp.com"
    }
  ]
  apps = [
    {
      helm_repo_url = "https://oauth2-proxy.github.io/manifests"
      helm_chart_version = "6.23.1"
      values = <<EOT
      config:
        clientID: ${local.openid_client_id_oauth2_proxy}
        clientSecret: ${dependency.infra_variables.outputs.variables.openid_client_secret_oauth2_proxy}
        cookieSecret: ${run_cmd("--terragrunt-quiet", "sh", "-c", "openssl rand -base64 32 | head -c 32 | base64")}
      extraArgs:
        provider: "gitlab"
        cookie-secure: false
        reverse-proxy: true
        cookie-csrf-per-request: true
        cookie-csrf-expire: "5m"
        cookie-domain: ".{{domen}}"
        reverse-proxy: true
        set-xauthrequest: true
        set-authorization-header: true
        pass-authorization-header: true
        pass-access-token: true
        skip-provider-button: true
        upstream: static://200
        gitlab-group: "from-the-lamp"
        whitelist-domain: ".{{domen}}"
        email-domain: "*"
        oidc-issuer-url: "https://gitlab.com"
        redirect-url: "https://oauth2.{{domen}}/oauth2/callback"
        scope: "openid email"
      EOT
    },
    {
      app_name = "oauth2-proxy-gateway"
      helm_chart_name = "istio-gateway"
      helm_chart_version = "0.0.8"
      values = <<EOT
      hosts:
      - oauth2.{{domen}}
      external: true
      virtualService:
        destination:
          host: oauth2-proxy
          port: 80
      EOT
    }
  ]
}
