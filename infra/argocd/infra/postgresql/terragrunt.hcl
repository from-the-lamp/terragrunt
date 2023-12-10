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
      helm_repo_url = "https://charts.bitnami.com/bitnami"
      helm_chart_version = "13.2.1"
      values = <<EOT
      auth:
        enablePostgresUser: true
        postgresPassword: "postgres"
      primary:
        nodeSelector:
          node-role: "worker"
      readReplicas:
        nodeSelector:
          node-role: "worker"
      cronjob:
        nodeSelector:
          node-role: "worker"
      EOT
    }
  ]
}
