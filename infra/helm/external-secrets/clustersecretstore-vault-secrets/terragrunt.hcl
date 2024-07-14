include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/kubernetes/helm.hcl"
}

inputs = {
  helm_chart_name = "./chart"
  helm_repo_url = ""
  helm_values_file = <<-EOF
  vault:
    url: http://vault.vault.svc.default.cluster.local
    token: ${get_env("VAULT_TOKEN")}
    engine:
      version: v2
      path: secrets
  EOF
}
