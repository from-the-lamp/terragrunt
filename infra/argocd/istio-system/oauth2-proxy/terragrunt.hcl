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
  oauth2_proxy_openid_client_id = local.common_settings.locals.oauth2_proxy_openid_client_id
}

dependency "get_infra_variables" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/get_infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    variables = {
      oauth2_proxy_openid_client_secret = "fake-secret"
    }
  }
}

inputs = {
  project = "infra"
  dest_cluster_list = [
    {
      cluster = "in-cluster"
      domen = "from-the-lamp.com"
    }
  ]
  apps = [
    {
      values = <<EOT
      config:
        clientID: ${local.oauth2_proxy_openid_client_id}
        clientSecret: ${dependency.get_infra_variables.outputs.variables.oauth2_proxy_openid_client_secret}
        cookieSecret: ${run_cmd("--terragrunt-quiet", "sh", "-c", "openssl rand -base64 32 | head -c 32 | base64")}
      extraArgs:
        provider: "gitlab"
        cookie-secure: false
        reverse-proxy: true
        set-xauthrequest: true
        set-authorization-header: true
        pass-authorization-header: true
        pass-access-token: true
        skip-provider-button: true
        upstream: static://200
        gitlab-group: "from-the-lamp"
        whitelist-domain: ".from-the-lamp.com"
        email-domain: "*"
        oidc-issuer-url: "https://gitlab.com"
        redirect-url: "https://oauth2.from-the-lamp.com/oauth2/callback"
        scope: "openid email"
      EOT
    }
  ]
}
