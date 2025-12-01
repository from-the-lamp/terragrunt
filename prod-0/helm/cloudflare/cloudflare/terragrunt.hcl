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
  helm_chart_name    = "lamp-cloudflared"
  helm_chart_version = "0.0.1"
  helm_values        = [file("./values.yaml")]
  helm_set_sensitive = {
    "cloudflare.tunnel_token" = dependency.tunnel.outputs.token
  }
}
