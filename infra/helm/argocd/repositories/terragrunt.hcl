include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  infra_helm_repo_url = local.common_settings.locals.infra_helm_repo_url
  gitlab_token = local.common_settings.locals.gitlab_token
}
  
dependency "argocd" {
  config_path = "../argocd"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

inputs = {
  helm_chart_name = "argocd-repositories"
  helm_chart_version = "0.0.2" 
  helm_values_file = <<-EOF
  credentials:
    freqtrade:
      type: git
      url: https://gitlab.com/djinno/freqtrade
      username: gitlab-ci-user
      password: ${local.gitlab_token}
    3commas:
      type: git
      url: https://gitlab.com/djinno/3commas
      username: gitlab-ci-user
      password: ${local.gitlab_token}
  repositories:
    infra:
      type: helm
      url: ${local.infra_helm_repo_url}
      enableOCI: "false"
    origin-ca-issuer:
      type: helm
      url: ghcr.io/cloudflare/origin-ca-issuer-charts
      enableOCI: "true"
    bitnami-oci:
      type: helm
      url: registry-1.docker.io/bitnamicharts
      enableOCI: "true"
    bitnami:
      type: helm
      url: https://charts.bitnami.com/bitnami
      enableOCI: "false"
    prometheus-community:
      type: helm
      url: https://prometheus-community.github.io/helm-charts
      enableOCI: "false"
    grafana:
      type: helm
      url: https://grafana.github.io/helm-charts
      enableOCI: "false"
  EOF
}
