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
          # Pods were overcommitted enough (limits summing to 170%+ of
          # allocatable) that a memory spike got the kernel OOM killer to
          # pick kube-apiserver as victim instead of a pod - repeatedly,
          # cascading into node NotReady flapping. systemReserved/
          # kubeReserved shrink Allocatable, which shrinks the kubepods
          # cgroup's cap (kubelet's default enforceNodeAllocatable already
          # includes "pods") - so an overcommitted pod now gets OOM-killed
          # inside that cgroup instead of system processes competing for
          # the same RAM. evictionHard/Soft make kubelet proactively evict
          # before it gets that far. Deliberately NOT setting
          # systemReservedCgroup/kubeReservedCgroup - kubelet refuses to
          # start on an invalid cgroup path, not worth the risk of bricking
          # all 3 control-plane nodes at once for a guessed Talos cgroup
          # name.
          extraConfig = {
            systemReserved = {
              cpu    = "250m"
              memory = "512Mi"
            }
            kubeReserved = {
              cpu    = "250m"
              memory = "512Mi"
            }
            evictionHard = {
              "memory.available" = "500Mi"
            }
            evictionSoft = {
              "memory.available" = "750Mi"
            }
            evictionSoftGracePeriod = {
              "memory.available" = "1m30s"
            }
          }
        }
      }
      cluster = {
        allowSchedulingOnControlPlanes = true
        apiServer = {
          extraArgs = {
            "anonymous-auth" = "true"
          }
        }
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
          # Talos/kubeadm defaults (10.244.0.0/16 pod, 10.96.0.0/12 service)
          # collide with another org's private ranges reachable over the
          # same tailnet - moved out of 10.0.0.0/8 entirely into
          # 172.16.0.0/12, which nothing else on the tailnet uses.
          podSubnets     = ["172.20.0.0/16"]
          serviceSubnets = ["172.21.0.0/16"]
        }
      }
    })
  ]
}
