include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/namespaces.hcl"
}

inputs = {
    namespaces = {
        "${basename(dirname(get_terragrunt_dir()))}" = {
          labels = [
            {label="istio-injection", value="enabled"},
            {label="kiali.io/member-of", value="istio-system"},
          ] 
        }
    }
}
