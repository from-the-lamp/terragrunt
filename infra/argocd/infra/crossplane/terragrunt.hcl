include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

inputs = {
  apps = [
    {
      helm_chart_version = "1.14.3"
      helm_repo_url = "https://charts.crossplane.io/stable"
    }
  ]
}
