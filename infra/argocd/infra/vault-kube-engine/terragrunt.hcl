include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

locals {
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  crossplane_workspaces_version = local.versions.locals.crossplane_workspaces
}

inputs = {
  apps = [
    {
      helm_chart_name = "crossplane-workspaces"
      helm_chart_version = local.crossplane_workspaces_version
      values = <<EOT
      workspaces:
        vault:
          enabled: true
          dir: kubernetes_engine
          vars:
          - key: kubernetes_host
            value: ""https://$KUBERNETES_PORT_443_TCP_ADDR:443""
      providers:
        vault:
          enabled: true
      EOT
    }
  ]
}
