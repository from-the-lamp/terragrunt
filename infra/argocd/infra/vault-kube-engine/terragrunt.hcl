include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

inputs = {
  apps = [
    {
      helm_chart_name = "crossplane-workspaces"
      helm_chart_version = "0.0.18"
      values = <<EOT
      workspaces:
        vault:
          enabled: true
          dir: kubernetes_engine
          vars:
          - key: kubernetes_host
            value: "https://$KUBERNETES_PORT_443_TCP_ADDR:443"
      providers:
        vault:
          enabled: true
      EOT
    }
  ]
}
