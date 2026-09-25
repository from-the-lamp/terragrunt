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
  helm_chart_name    = "lamp-hcloud-cloud-controller-manager"
  helm_chart_version = "0.1.0"
  # Overrides the wrapper chart's default (networking.enabled: false) without
  # touching the separately-published infra/helm-charts repo. Needed so the CCM
  # reports each node's private network IP as InternalIP — without it, the
  # CCM's own address list has no match for the node's kubelet-reported private
  # IP and it refuses to initialize the node at all (no providerID, no
  # ExternalIP either). clusterCIDR is left at the chart default (10.244.0.0/16),
  # which matches this cluster's actual pod CIDR.
  helm_values = [
    yamlencode({
      "hcloud-cloud-controller-manager" = {
        networking = {
          enabled = true
        }
      }
    })
  ]
}
