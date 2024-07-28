include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/kubernetes/helm.hcl"
}

inputs = {
  helm_chart_name    = "config"
  helm_chart_version = "0.0.5"
  helm_values_file   = <<-EOF
  global:
    secret:
      credentials: |-
        {
          "host": "http://vault.vault.svc.cluster.local:8200",
          "token": "${get_env("VAULT_TOKEN")}"
        }
  EOF
}
