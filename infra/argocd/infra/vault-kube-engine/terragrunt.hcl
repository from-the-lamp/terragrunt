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
      helm_chart_version = "0.1.0"
      values = <<EOT
      workspaces:
        vault:
          enabled: true
          dir: kubernetes_engine
      EOT
    }
  ]
}
