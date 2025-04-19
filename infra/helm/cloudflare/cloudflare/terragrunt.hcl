include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/kubernetes/helm.hcl"
}

dependency "tunnel" {
  config_path = "../tunnel"
  mock_outputs = {
    token = "fake-token"
  }
}

inputs = {
  helm_chart_name    = "cloudflare-tunnel-remote"
  helm_chart_version = "0.1.1"
  helm_repo_url      = "https://cloudflare.github.io/helm-charts"
  helm_set_sensitive = {
    "cloudflare.tunnel_token" = dependency.tunnel.outputs.token
  }
}
