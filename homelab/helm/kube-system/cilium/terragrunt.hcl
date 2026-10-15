include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/homelab/helm.hcl"
}

inputs = {
  helm_chart_name    = "lamp-cilium"
  helm_chart_version = "0.1.1"
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
        }
      }
    })
  ]
}
