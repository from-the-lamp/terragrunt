include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/hetzner/helm.hcl"
}

# ArgoCD's manifests reference ExternalSecret CRDs; applying it in parallel
# with external-secrets (the default under `run --all`) races the CRD
# registration and intermittently fails. Force external-secrets first.
dependency "external_secrets" {
  config_path                             = "${get_repo_root()}/hetzner/helm/external-secrets/external-secrets"
  mock_outputs_allowed_terraform_commands = ["plan", "apply", "validate", "output", "init", "destroy"]
  skip_outputs                            = true
}

inputs = {
  helm_chart_name    = "lamp-argocd"
  helm_chart_version = "0.4.0"
  # Chart default leaves this empty, which registers the in-cluster Secret
  # with no name at all — Applications in any project other than "default"
  # then fail to resolve destination.name: in-cluster (project destination
  # matching needs an actual registered cluster name, not just the
  # ArgoCD-wide magic string), erroring "destination server '' ... do not
  # match any of the allowed destinations".
  helm_values = [
    yamlencode({
      defaultClusterName = "in-cluster"
    })
  ]
}
