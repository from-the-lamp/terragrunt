include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

inputs = {
  helm_internal_repo = true
  helm_chart_name    = "origin-ca-issuer-controller"
  helm_chart_version = "0.5.1"
}
