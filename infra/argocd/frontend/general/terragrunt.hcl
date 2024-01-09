include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

inputs = {
  app_annotations = {}
  dest_cluster_list = [
    {
      cluster = "prod-0"
      domen = "from-the-lamp.com"
    }
  ]
  apps = [
    {
      helm_chart_path = "base"
      helm_chart_name = ""
      helm_chart_version = "HEAD"
      remote_value_file = true
      value_file_repo_url = "https://gitlab.com/from-the-lamp/frontend/general.git"
      value_file = "$values/values.yml"
      values = <<EOT
      global:
        version: latest
        image:
          name: registry.gitlab.com/from-the-lamp/frontend/general
          tag: latest
      gateway:
        hosts: 
        - "{{domen}}"
      EOT
    }
  ]
}
