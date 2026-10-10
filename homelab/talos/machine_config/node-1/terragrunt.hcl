include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/talos/machine_configuration_bare_metal.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  lan_subnet       = local.environment_vars.locals.lan_subnet
  lan_gateway      = local.environment_vars.locals.lan_gateway
  pod_subnets      = local.environment_vars.locals.pod_subnets
  service_subnets  = local.environment_vars.locals.service_subnets
  hostname         = local.environment_vars.locals.node_1_hostname
  node_ip          = local.environment_vars.locals.node_1_ip
  interface        = local.environment_vars.locals.node_1_interface
}

dependency "secrets" {
  config_path = "${get_repo_root()}/homelab/talos/secrets"
  # "plan" deliberately excluded: talos_machine_configuration parses these as
  # real PEM material even during plan, so a mock value would crash instead
  # of a clean "apply talos/secrets first" error.
  mock_outputs_allowed_terraform_commands = ["validate", "output", "init", "destroy"]
  mock_outputs = {
    machine_secrets = {
      certs = {
        etcd               = { cert = "fake", key = "fake" }
        k8s                = { cert = "fake", key = "fake" }
        k8s_aggregator     = { cert = "fake", key = "fake" }
        k8s_serviceaccount = { key = "fake" }
        os                 = { cert = "fake", key = "fake" }
      }
      cluster = {
        id     = "fake"
        secret = "fake"
      }
      secrets = {
        aescbc_encryption_secret    = "fake"
        bootstrap_token             = "fake"
        secretbox_encryption_secret = "fake"
      }
      trustdinfo = {
        token = "fake"
      }
    }
  }
}

inputs = {
  # No Load Balancer - single node, talk to it directly.
  cluster_endpoint = "https://${local.node_ip}:6443"
  machine_secrets  = dependency.secrets.outputs.machine_secrets

  config_patches = [
    yamlencode({
      machine = {
        network = {
          hostname = local.hostname
          interfaces = [
            {
              interface = local.interface
              addresses = ["${local.node_ip}/24"]
              routes = [
                {
                  network = "0.0.0.0/0"
                  gateway = local.lan_gateway
                }
              ]
            }
          ]
        }
        kubelet = {
          nodeIP = {
            validSubnets = [local.lan_subnet]
          }
          # Same OOM-protection mechanism as Hetzner's
          # (_common/talos/machine_configuration.hcl), loosened: those
          # thresholds were sized for 16GB nodes, this one has 64GB.
          extraConfig = {
            systemReserved = {
              cpu    = "250m"
              memory = "1Gi"
            }
            kubeReserved = {
              cpu    = "250m"
              memory = "1Gi"
            }
            evictionHard = {
              "memory.available" = "1Gi"
            }
            evictionSoft = {
              "memory.available" = "1.5Gi"
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
          advertisedSubnets = [local.lan_subnet]
        }
        # The one load-bearing difference from Hetzner's own patch: no
        # hcloud-cloud-controller-manager exists here to initialize the
        # node, so kubelet must NOT run with --cloud-provider=external, or
        # it waits forever for a CCM that will never show up.
        externalCloudProvider = {
          enabled = false
        }
        network = {
          # Same as Hetzner: Talos's bundled Flannel is disabled, Cilium is
          # installed separately via Helm instead, for parity across
          # clusters.
          cni = {
            name = "none"
          }
          podSubnets     = local.pod_subnets
          serviceSubnets = local.service_subnets
        }
      }
    })
  ]
}
