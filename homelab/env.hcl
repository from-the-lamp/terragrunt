locals {
  environment        = "homelab"
  cluster_name       = "homelab"
  # Upgraded in-place from the original v1.9.0/1.31.4 bootstrap through
  # v1.10-v1.14 via homelab/talos/{kubernetes_upgrade,os_upgrade}. v1.14.2
  # itself had been stuck (talosctl reported success but the node never
  # rebooted into it, 3x) - it turned out to just need a real power cycle,
  # which happened as a side effect of the physical network move; confirmed
  # live via `talosctl version` (Server Tag: v1.14.2) post-move.
  talos_version      = "v1.14.2"
  kubernetes_version = "1.36.5"

  # System extensions baked into the installer image (Image Factory slugs).
  # amd-ucode for the UM890 Pro's Ryzen CPU - add a NIC driver extension
  # here too if the box's chipset turns out to need one (check once the
  # hardware is in hand).
  talos_extensions   = ["siderolabs/amd-ucode"]
  talos_architecture = "x86"

  # Pod/service subnets advertised into the same tailnet Hetzner's own
  # subnet router uses (172.20.0.0/16 pods / 172.21.0.0/16 services) - these
  # must NOT overlap. 172.24/172.25 is the next free-looking block but is
  # NOT verified against oracle-prod-0/1 or anything else already
  # advertised - check the Tailscale admin console (Machines -> routes)
  # before first apply.
  pod_subnets     = ["172.24.0.0/16"]
  service_subnets = ["172.25.0.0/16"]

  # Moving off the shared home LAN (192.168.1.0/24) onto the dedicated
  # GL.iNet WISP-mode router's own default LAN range, now that it's in
  # hand. Pushed via homelab/talos/apply_config/node-1 with mode=staged -
  # written now but only takes effect on the node's next reboot, so this
  # edit alone does not disrupt the node while it's still physically
  # cabled to the old network. cluster.etcd.advertisedSubnets and
  # kubelet.nodeIP.validSubnets both key off lan_subnet already (not a
  # literal IP), so they pick up the new range automatically - no separate
  # edit needed there. cluster_endpoint (in machine_config/node-1) is
  # derived from node_1_ip below for the same reason.
  lan_subnet  = "192.168.8.0/24"
  lan_gateway = "192.168.8.1"

  # Per-node static network identity. Add node_2_*/node_3_*/node_4_* the
  # same way when those boxes show up - nothing here assumes exactly one
  # node, it's just that only one exists so far.
  node_1_hostname = "homelab-node-1"
  node_1_ip       = "192.168.8.11"
  # Confirmed via console output at first boot: this box has two Realtek
  # 2.5GbE NICs (enp2s0, enp3s0), not one - using enp2s0 as primary. Switch
  # to enp3s0 here (and re-render config.yaml) if the other physical port
  # ends up being the one actually cabled.
  node_1_interface = "enp2s0"
}
