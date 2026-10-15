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
  talos_version    = local.environment_vars.locals.talos_version
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
        # disk: not set anywhere else (Hetzner's cloud VMs have exactly one
        # disk, so auto-detection is unambiguous there - this box has
        # multiple M.2 slots, and the booting USB installer itself is also
        # a visible block device). Confirmed via the boot dmesg on first
        # boot: a single "nvme nvme0" device, i.e. /dev/nvme0n1.
        # wipe: true - disk alone only picks the install TARGET, it does
        # NOT imply wiping (that's this separate, default-false flag). The
        # NVMe's prior contents are unknown (could be a Windows
        # pre-install, could be residue from an earlier aborted attempt on
        # this same box) - without this, install failed partway through
        # partition writes with "task install ... failed: task \"upgrade\"
        # failed: exit code 2".
        install = {
          disk = "/dev/nvme0n1"
          wipe = true
          # The talos provider auto-fills this field with its OWN default
          # installer image/tag (observed: a schematic unrelated to ours,
          # pinned to v1.14.0) regardless of the talos_version input - that
          # input only affects which config schema/fields are valid to
          # render, not this field. Left unset, the install pulled a
          # v1.14.0 installer against a v1.9.0/Kubernetes-1.31.4 config and
          # failed the same way the original stale-ISO version mismatch
          # did. This schematic is amd-ucode only, no talos.config kernel
          # arg (that's only needed for the boot-time installer medium,
          # not the permanently-installed system).
          image = "factory.talos.dev/metal-installer/96f8c146a67c80daad900d3fc1a6976fe11062321eee9ab6ae2a6aea88b2d26e:${local.talos_version}"
        }
        network = {
          # hostname: NOT set here - Talos 1.12+ ships a default
          # HostnameConfig document (auto: stable) that conflicts with
          # machine.network.hostname ("static hostname is already set in
          # v1alpha1 config", confirmed live on this node on v1.13.11).
          # Set explicitly below instead, as its own document, with auto
          # disabled.
          # Explicit nameservers + dhcp=false: without dhcp=false, DHCP
          # stayed active alongside this static address, so the node ended
          # up with a SECOND, DHCP-assigned IP competing as its "current"
          # address, and DHCP-supplied resolvers (100.100.1.1/100.100.0.1 -
          # Tailscale's reserved MagicDNS IPs, presumably pushed by the
          # home router itself acting as a Tailscale subnet router) instead
          # of real DNS - every lookup (image pulls, NTP, discovery.talos.dev)
          # failed with "server misbehaving", which blocked the etcd image
          # pull and left kubelet/etcd stuck in Preparing waiting on CRI.
          nameservers = ["1.1.1.1", "8.8.8.8"]
          interfaces = [
            {
              interface = local.interface
              dhcp      = false
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
        # Lets an in-cluster CronJob (apps/homelab/platform/talos-backup)
        # call the Talos API to take etcd snapshots, scoped to the
        # narrowest role that exists for this - os:etcd:backup grants
        # nothing beyond "take a snapshot and read it back", not general
        # node/API access.
        features = {
          kubernetesTalosAPIAccess = {
            enabled                     = true
            allowedRoles                = ["os:etcd:backup"]
            allowedKubernetesNamespaces = ["talos-backup"]
          }
        }
        kubelet = {
          nodeIP = {
            validSubnets = [local.lan_subnet]
          }
          # Same OOM-protection mechanism as Hetzner's
          # (_common/talos/machine_configuration.hcl), loosened: those
          # thresholds were sized for 16GB nodes, this one has 64GB.
          extraConfig = {
            # Default (110) is Kubernetes' own tested/supported ceiling,
            # not a hard limit - this single node has 16 cores/64GB with
            # plenty of headroom (3%/19% used at 136 pods). The real
            # ceiling is the Cilium cluster-pool /24 per-node podCIDR
            # (254 usable IPs, confirmed via `kubectl get node -o
            # jsonpath='{.spec.podCIDRs}'`) - mask size can't be changed
            # on an existing cluster, so 250 is the practical max without
            # a full CIDR migration.
            maxPods = 250
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
    }),
    # Separate v1alpha1 document, not a field under machine.network -
    # that's the whole point: this is what replaces the old
    # machine.network.hostname mechanism in Talos 1.12+.
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "HostnameConfig"
      hostname   = local.hostname
      auto       = "off"
    })
  ]
}
