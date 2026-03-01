include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/cloudflare/tunnel.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
}

inputs = {
  tunnel_name                     = local.env
  enable_identity_provider_gitlab = true
  identity_provider_gitlab = {
    name          = "GitLab"
    issuer_url    = "https://gitlab.com"
    client_id     = get_env("OPENID_CLIENT_ID_CLOUDFLARE")
    client_secret = get_env("OPENID_CLIENT_SECRET_CLOUDFLARE")
    auth_url      = "https://gitlab.com/oauth/authorize"
    token_url     = "https://gitlab.com/oauth/token"
    certs_url     = "https://gitlab.com/oauth/discovery/keys"
    scopes        = ["openid", "profile", "email"]
  }
  tunnel_routes = [
    {
      network = "10.43.0.0/16"
      comment = "Services"
    },
  ]
  split_tunnels = [
    {
      address     = "10.43.0.0/16"
      description = "Services"
    },
  ]
  private_domains = [
    {
      suffix      = "internal.from-the-lamp.work"
      description = "Infra: Private DNS resolver"
      dns_servers = ["10.43.41.154"]
    },
    {
      suffix      = "internal.from-the-lamp.com"
      description = "Prod-0: Private DNS resolver"
      dns_servers = ["10.43.93.137"]
    }
  ]
}