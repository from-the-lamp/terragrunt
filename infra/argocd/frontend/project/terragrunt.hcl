include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/project.hcl"
}

inputs = {
  destinations = [
    {
      name = "*"
      namespace = basename(dirname(get_terragrunt_dir()))
    },
    {
      name = "*"
      namespace = "istio-system"
    }
  ]
}
