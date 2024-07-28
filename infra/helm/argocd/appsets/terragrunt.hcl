include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/kubernetes/helm.hcl"
}

dependency "argocd" {
  config_path                             = "../argocd"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs                            = true
}

inputs = {
  helm_repo_url      = "https://argoproj.github.io/argo-helm"
  helm_chart_name    = "argocd-apps"
  helm_chart_version = "2.0.0"
  helm_values_file   = file("values.yaml")
}
