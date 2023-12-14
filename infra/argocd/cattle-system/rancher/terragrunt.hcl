include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

inputs = {
  project = "infra"
  namespace_labels = {
    "istio-injection" = "disabled"
  }
  dest_cluster_list = [
    {
      cluster = "in-cluster"
      domen = "from-the-lamp.work"
    }
  ]
  apps = [
    {
      helm_repo_url = "https://releases.rancher.com/server-charts/stable"
      helm_chart_version = "2.7.9"
      values = <<EOT
      replicas: 1
      bootstrapPassword: "admin"
      ingress:
        enabled: false
      EOT
    },
    {
      app_name = "rancher-gateway"
      helm_chart_name = "istio-gateway"
      helm_chart_version = "0.0.7" 
      values = <<EOT
      hosts:
      - "rancher.{{domen}}"
      external: true
      virtualService:
        destination:
          host: rancher
          port: 80
      EOT
    }
  ]
}
