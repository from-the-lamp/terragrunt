include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/homelab/helm.hcl"
}

inputs = {
  helm_chart_name = "lamp-cilium"
  # 0.1.1 is no longer in the registry (either its push pipeline got
  # auto-cancelled by the next version-bump commit before the push stage
  # ran, or a registry retention policy pruned it since - either way "tofu
  # apply" failed with "Unable to locate chart ... 0.1.1: not found").
  # Picking up the chart's current published version instead, which also
  # carries forward chart fixes since 0.1.1: cni.exclusive=false (istio-cni
  # chaining), DaemonSet rollout maxUnavailable=1, cilium 1.20.3->1.20.4.
  helm_chart_version = "0.1.4"
  # Chart default (MTU: 0) auto-detects the underlying device's MTU, but
  # devices: "" (also chart default) means Cilium can't actually find the
  # physical NIC to auto-detect from on this single-NIC bare-metal node -
  # pod interfaces ended up at the physical 1500 instead of accounting for
  # VXLAN's ~50 byte overhead (routing-mode: tunnel, tunnel-protocol:
  # vxlan). With packetization-layer-pmtud-mode: blackhole (also default,
  # ignores ICMP "fragmentation needed"), any outbound request whose
  # encapsulated size exceeded the physical path's real MTU just silently
  # dropped mid-transfer - confirmed live: a GET to Backblaze B2 always
  # succeeded, but every PUT (WAL archive, S3 upload, regardless of tool -
  # barman-cloud, rclone, plain aws-cli all reproduced it identically)
  # failed with "Connection was closed before we received a valid
  # response." Explicit 1450 (1500 - 50) fixes the actual packet size
  # instead of relying on auto-detection.
  helm_values = [
    yamlencode({
      cilium = {
        MTU = 1450
        # Chart default (2) leaves a second operator replica permanently
        # Pending on this single-node cluster - nothing to schedule it to.
        operator = {
          replicas = 1
          prometheus = {
            serviceMonitor = {
              enabled = true
            }
          }
          # Chart default ships cilium-operator with no resources - sized
          # conservatively (it's a lightweight controller, not a dataplane
          # component). No cpu limit, matching this platform's general
          # policy of request-only CPU.
          resources = {
            requests = {
              cpu    = "10m"
              memory = "64Mi"
            }
            limits = {
              memory = "192Mi"
            }
          }
        }
        prometheus = {
          enabled = true
          serviceMonitor = {
            enabled = true
          }
        }
        hubble = {
          tls = {
            auto = {
              method = "cronJob"
            }
          }
          metrics = {
            enabled = ["dns", "drop", "tcp", "flow", "icmp", "http", "port-distribution"]
            serviceMonitor = {
              enabled = true
            }
          }
        }
        # Chart default ships cilium-agent with no resources at all - the
        # CNI DaemonSet was BestEffort, same gap the platform/limits
        # ValidatingAdmissionPolicy flags elsewhere but can't reach here
        # (kube-system is exempted from that policy). Sized from one
        # live-cluster pods_top reading (agent ~100m CPU/~500Mi memory)
        # plus headroom - no cpu limit, matching this platform's general
        # policy of request-only CPU. Revisit once a real DNS/connection-
        # churn spike has been observed.
        resources = {
          requests = {
            cpu    = "50m"
            memory = "256Mi"
          }
          limits = {
            memory = "768Mi"
          }
        }
      }
    })
  ]
}
