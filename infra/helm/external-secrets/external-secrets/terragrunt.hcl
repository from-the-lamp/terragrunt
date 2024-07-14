include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/kubernetes/helm.hcl"
}

inputs = {
  helm_chart_name = "external-secrets"
  helm_chart_version = "0.9.19"
  helm_repo_url = "https://charts.external-secrets.io"
  helm_values_file = <<-EOF
EOF
}
