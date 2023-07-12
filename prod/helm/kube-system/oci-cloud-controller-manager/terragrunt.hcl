include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

inputs = {
  helm_internal_repo    = true
  helm_chart_name       = "oci-cloud-controller-manager"
  helm_chart_version    = "0.0.1"
}
