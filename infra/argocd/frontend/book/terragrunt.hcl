include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application.hcl"
}

locals {
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  crossplane_providers_version = local.versions.locals.crossplane_providers
}

inputs = {
  apps = [
    {
      helm_chart_name = "base"
      remote_value_file = true
      value_file_repo_url = "https://gitlab.com/from-the-lamp/frontend/book.git"
      value_file = "$values/values.yml"
      values = <<EOT
      global:
        image:
          name: registry.gitlab.com/from-the-lamp/frontend/book
          tag: latest
      EOT
    }
  ]
}
