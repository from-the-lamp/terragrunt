include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/kubernetes/helm.hcl"
}

dependency "argocd" {
  config_path                             = "../argocd"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs                            = true
}

inputs = {
  helm_chart_name    = "argocd-apps"
  helm_repo_url      = "https://argoproj.github.io/argo-helm"
  helm_chart_version = "2.0.0"
  helm_values        = [file("./values.yaml")]
}
