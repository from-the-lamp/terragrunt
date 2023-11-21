include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  crossplane_version = local.versions.locals.crossplane
}

inputs = {
  helm_repo_url = "https://charts.crossplane.io/stable"
  helm_chart_version = local.crossplane_version
  helm_set_sensitive = {
  }
}
