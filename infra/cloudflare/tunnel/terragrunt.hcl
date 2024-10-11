include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path   = "${dirname(find_in_parent_folders())}/_common/cloudflare/tunnel.hcl"
  expose = true
}

locals {
  env = include.common.locals.env
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
      comment = "Canal service-cidr"
    },
  ]
  split_tunnels = [
    {
      address     = "10.43.248.121/32"
      description = "Private Istio Gateway"
    },
    {
      address     = "10.43.131.35/32"
      description = "Private DNS resolver"
    },
  ]

  private_domains = [
    {
      suffix      = "from-the-lamp.org"
      description = "Private DNS"
      dns_servers = ["10.43.131.35"]
    },
  ]
}