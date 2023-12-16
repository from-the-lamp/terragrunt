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
      helm_chart_version = "0.0.1"
      values = <<EOT
      spec:
        runAsUser: "root"
        commandAction: "bash"
        exposureMode: "ClusterIP"
        ttl: 500
        once: false
      EOT
    },
    {
      app_name = "cloudshell-gateway"
      helm_chart_name = "istio-gateway"
      helm_chart_version = "0.0.8"
      values = <<EOT
      hosts:
      - cloudshell.{{domen}}
      external: true
      auth: 
        enabled: true
      virtualService:
        destination:
          host: cloudshell-cloudshell
          port: 7681
      EOT
    }
  ]
}
