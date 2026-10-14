locals {
  environment        = "homelab"
  cluster_name       = "homelab"
  # Reverted to v1.9.0/1.31.4 for now - v1.14.2's ISO isn't cached on Image
  # Factory yet (cold build + repeated HTTP/2 stream errors mid-download).
  # Bootstrap on this known-good, already-cached version first; upgrade to
  # v1.14.2 later once the cluster is actually running (Talos upgrades are
  # in-place and don't require re-flashing a USB stick).
  talos_version      = "v1.9.0"
  kubernetes_version = "1.31.4"

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

  # TEMPORARY: GL.iNet router hasn't arrived yet. Internet Connection
  # Sharing (NAT, 192.168.137.0/24) was tried first but is one-way -
  # outbound from the node works, but nothing on the Mac's own network can
  # initiate a connection INTO that NAT'd subnet (no port forwarding in
  # ICS), which broke the Terraform-driven bootstrap/access steps even
  # though config-serving-over-HTTP worked fine. Switched the Windows PC
  # from ICS to a Network Bridge instead (WiFi+Ethernet bridged at L2, no
  # NAT) - the node is now a normal DHCP client directly on the shared
  # home LAN, same subnet as every other device. Revert to 192.168.8.0/24
  # (GL.iNet's own default LAN range) + node_1_ip 192.168.8.10 once the
  # dedicated WISP-mode router is in hand - don't leave this node on the
  # shared home LAN long-term.
  lan_subnet  = "192.168.1.0/24"
  lan_gateway = "192.168.1.1"

  # Per-node static network identity. Add node_2_*/node_3_*/node_4_* the
  # same way when those boxes show up - nothing here assumes exactly one
  # node, it's just that only one exists so far.
  node_1_hostname = "homelab-node-1"
  node_1_ip       = "192.168.1.24"
  # Confirmed via console output at first boot: this box has two Realtek
  # 2.5GbE NICs (enp2s0, enp3s0), not one - using enp2s0 as primary. Switch
  # to enp3s0 here (and re-render config.yaml) if the other physical port
  # ends up being the one actually cabled.
  node_1_interface = "enp2s0"
}
