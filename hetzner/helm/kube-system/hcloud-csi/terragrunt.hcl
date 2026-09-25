include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/hetzner/helm.hcl"
}

dependency "hcloud_token_secret" {
  config_path                             = "${get_repo_root()}/hetzner/helm/kube-system/hcloud-token-secret"
  mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate", "output", "init", "destroy"]
  skip_outputs                            = true
}

inputs = {
  helm_chart_name    = "lamp-hcloud-csi"
  helm_chart_version = "0.1.0"
}
