include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

inputs = {
  dest_cluster_list = [
    {
      cluster = "prod-0"
      domen = "from-the-lamp.com"
    }
  ]
  apps = [
    {
      helm_chart_name = "cloudtty"
      helm_chart_version = "0.5.0"
      helm_repo_url = "https://cloudtty.github.io/cloudtty"
      values = <<EOT
      cloudshellImage:
        registry: ghcr.io
        repository: cloudtty/cloudshell
        tag: "v0.5.8"
      podLabels:
        sidecar.istio.io/inject: "false"
      EOT
    }
  ]
}
