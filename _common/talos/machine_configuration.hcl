terraform {
  source = "${get_repo_root()}/_modules/talos/machine_configuration"
}

locals {
  environment_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  cluster_name        = local.environment_vars.locals.cluster_name
  talos_version       = local.environment_vars.locals.talos_version
  kubernetes_version  = local.environment_vars.locals.kubernetes_version
  private_subnet_cidr = local.environment_vars.locals.private_subnet_cidr
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "talos" {}
EOF
}

inputs = {
  cluster_name       = local.cluster_name
  machine_type       = "controlplane"
  talos_version      = local.talos_version
  kubernetes_version = local.kubernetes_version
  config_patches = [
    yamlencode({
      machine = {
        kubelet = {
          nodeIP = {
            validSubnets = [local.private_subnet_cidr]
          }
        }
      }
      cluster = {
        allowSchedulingOnControlPlanes = true
        etcd = {
          advertisedSubnets = [local.private_subnet_cidr]
        }
        # Lets kubelet run with --cloud-provider=external so hcloud-cloud-controller-manager
        # (already deployed via hetzner/helm/kube-system/hcloud-cloud-controller-manager) can
        # initialize each node: set providerID and report the public IPv4 as NodeExternalIP.
        externalCloudProvider = {
          enabled = true
        }
        # Talos's bundled Flannel conflicts with Cilium's pod routing to the
        # Hetzner metadata service (see README.md's "Known gotchas") — Cilium
        # is installed separately via hetzner/helm/kube-system/cilium.
        network = {
          cni = {
            name = "none"
          }
        }
      }
    })
  ]
}
