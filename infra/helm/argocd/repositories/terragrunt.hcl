include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  infra_helm_repo_url = local.common_settings.locals.infra_helm_repo_url
}

inputs = {
  helm_chart_name = "argocd-repositories"
  helm_chart_version = "0.0.2" 
  helm_values_file = <<-EOF
  repositories:
    infra:
      type: helm
      url: ${local.infra_helm_repo_url}
      enableOCI: "false"
    origin-ca-issuer:
      type: helm
      url: ghcr.io/cloudflare/origin-ca-issuer-charts
      enableOCI: "true"
    bitnami:
      type: helm
      url: registry-1.docker.io/bitnamicharts
      enableOCI: "true"
  EOF
}
