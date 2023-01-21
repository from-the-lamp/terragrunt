include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/helm.hcl"
}

dependency "origin-ca-issuer-crd" {
  config_path  = "../origin-ca-issuer-crd"
  skip_outputs = true
}

inputs = {
  helm_external_repo    = true
  helm_values_file      = "values.yml"
  helm_chart_name       = "origin-ca-issuer"
  helm_repo_url         = "https://cloudflare.github.io/origin-ca-issuer/charts"
  helm_chart_version    = "0.5.0"
}
