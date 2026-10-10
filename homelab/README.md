# homelab

Single-node bare-metal Talos cluster (UM890 Pro mini PC, 64GB RAM), reachable only over
Tailscale, behind a dedicated WISP-mode router (not the shared home LAN) - no public Load
Balancer, no cloud provider. See `apps/homelab/platform` in `infra/argo-apps` for the GitOps side
(forked from `apps/hetzner-infra/platform`).

Unlike `hetzner/`/`prod-0/`/`prod-1/`, there's no `hetzner/`-style resource layer here (network,
firewall, load balancer, node servers) - the node is physical hardware you flash and plug in, not
something `terraform apply` creates. What IS here, in `homelab/talos/`, mirrors Hetzner's own
`hetzner/talos/*` units almost exactly (same modules, same `talos` provider) - only the inputs
differ, since there's no load balancer/hcloud-node dependency to wire up and the network is
static instead of DHCP+metadata-service-provided.

## Before you start

Check `env.hcl`: `node_1_interface` is a placeholder (real name only known after first boot -
`talosctl get links` once it's up). Also verify in the Tailscale admin console (Machines ->
routes) that `pod_subnets`/`service_subnets` don't collide with oracle-prod-0/1 or anything else
already advertised in the tailnet - flagged inline in `env.hcl` too.

## Why Terraform, if there's no cloud resource to create

Not for creating the node - for everything that happens *after* it exists:

- `homelab/talos/secrets` - generates this cluster's root PKI (`talos_machine_secrets`). Doesn't
  need the node to exist at all; can be applied the moment this directory exists.
- `homelab/talos/machine_config/node-1` - renders the full machine configuration YAML
  (`data.talos_machine_configuration`, a pure data source, no live node needed either). This
  output is what `homelab:publish-config` serves from the router - see the bootstrap steps below.
- `homelab/talos/access` - runs `talos_machine_bootstrap` (the one-time etcd init, same thing
  `talosctl bootstrap` does) and `talos_cluster_kubeconfig` (fetches kubeconfig to
  `./kubeconfig.yaml`). Needs the node already up and configured - satisfied by fetching its
  config from the router at boot, not by Terraform itself.
- `homelab/talos/apply_config/node-1` - re-applies config to an already-bootstrapped node
  (version bumps, patch changes) via `talosctl apply-config`, reviewable through the same
  git-plan/apply flow as every other change in this repo instead of a one-off manual command.

`os_upgrade`/`kubernetes_upgrade` units (Hetzner has both) aren't set up yet - add them the same
way `hetzner/talos/os_upgrade`/`kubernetes_upgrade` are structured once there's an actual Talos
or Kubernetes version bump to do. Not needed to get the node running.

## Bootstrap

1. **Generate the cluster secrets and render the machine config - no hardware needed yet:**

   ```bash
   cd homelab/talos/secrets && terragrunt apply
   cd ../machine_config/node-1 && terragrunt apply
   ```

2. **Build the boot ISO and publish the config to the router** (run from this repo's root, on
   your own machine, not the cbox devcontainer - needs real USB access and SSH access to the
   GL.iNet):

   ```bash
   task homelab:boot-iso
   task homelab:publish-config
   ```

   `homelab:boot-iso` registers an Image Factory schematic (`siderolabs/amd-ucode` for the Ryzen
   CPU, plus the kernel arg `talos.config=http://192.168.8.1/config.yaml` baked in) and downloads
   the installer to `homelab/_generated/boot.iso`. `homelab:publish-config` renders node-1's
   machine config via `terragrunt output` and `scp`s it straight into the GL.iNet router's web
   root (`uhttpd` serves `/www` as-is by default, no extra package needed) - assumes SSH is
   enabled on the router (GL.iNet ships it on by default, `root` + the admin password; override
   the target with `ROUTER_SSH=user@host` if different). Only ONE USB stick is needed this way -
   the node gets a DHCP IP from the router at boot, fetches the config over the LAN, then switches
   to its static IP once the config is applied. Confirm the box's actual NIC chipset once you have
   it in hand; some Realtek 2.5GbE parts need their own extension added to `.tasks/homelab.yml`'s
   schematic customization to be recognized at all.

3. **Flash the USB stick:**

   ```bash
   lsblk                                 # or diskutil list on macOS - find the device path
   task homelab:flash DEVICE=/dev/sdX
   ```

   This prints the target device and the current block device list, then asks you to retype the
   device path before running `dd` - there's no way to invoke it with a device path that silently
   goes unconfirmed.

4. **Boot the node.** Plug in the USB stick, power on. It installs, fetches the config from the
   router over the LAN, applies it, and comes up already configured with its static IP - no
   console interaction. Once it's up, run `task homelab:unpublish-config` - the file on the router
   carries real cluster secrets and doesn't need to keep serving after this point.

5. **Bootstrap etcd and fetch kubeconfig:**

   ```bash
   cd homelab/talos/access && terragrunt apply
   # -> ./kubeconfig.yaml
   ```

6. **Install the CNI and External Secrets via Terraform** (nothing schedules without a CNI -
   `cluster.network.cni.name: none` in the machine config deliberately disables Talos's bundled
   Flannel; ESO has to exist before most apps' ExternalSecrets can resolve):

   ```bash
   cd homelab/helm/kube-system/cilium && terragrunt apply
   cd ../../external-secrets/external-secrets && terragrunt apply
   cd ../external-secrets-stores && terragrunt apply
   ```

   These three mirror `hetzner/helm/kube-system/cilium` and `hetzner/helm/external-secrets/*`
   exactly (same shared module, same chart names/versions) - only the provider wiring differs
   (talks to the node's own IP instead of a load balancer).

7. **No ArgoCD gets installed on this cluster.** There is exactly one ArgoCD in this whole org
   (Hetzner's), and it already manages oracle-prod-0/prod-1 as *external* clusters via registered
   kubeconfigs rather than running its own ArgoCD per cluster - homelab follows the same pattern,
   registered in `hetzner/helm/argocd/argocd/terragrunt.hcl`'s `externalClusters` list as
   `"homelab"`. (An earlier draft of this runbook had homelab running its own ArgoCD via
   Terraform - that was wrong: the shared `projects` chart in `infra/argo-apps` declares every
   environment's AppProject/ApplicationSet in one `values.yaml`, applied by that single ArgoCD -
   a second ArgoCD applying the same chart would also try to manage Hetzner's and prod-0/1's
   AppProjects with `destination: in-cluster` resolving to *this* cluster instead.)

   Once this node is up, push its kubeconfig into Hetzner's Vault so that `externalClusters`
   entry actually resolves:

   ```bash
   cd homelab/talos/access
   terragrunt output -raw kubeconfig_raw | base64 -w0 > /tmp/kubeconfig-homelab.b64
   vault kv patch toolhive kubeconfig-homelab=@/tmp/kubeconfig-homelab.b64
   rm /tmp/kubeconfig-homelab.b64
   ```

   From that point, Hetzner's ArgoCD syncs `apps/homelab/platform/*` into this cluster the same
   way it already does for prod-0/1 - including `vault`, `external-secrets`'s ClusterSecretStore
   consumer apps, and `local-path-provisioner` (which needs nothing beforehand - no
   ExternalSecret dependency, so it syncs whenever ArgoCD gets to it).

8. **Vault bootstrap-order caveat.** Most apps under `apps/homelab/platform` set
   `externalSecrets: name: vault`, resolved against the ClusterSecretStore step 6 already
   created - but that store only works once `apps/homelab/platform/vault` (an ordinary
   ArgoCD-managed app, not Terraform) is actually up and unsealed. Until then those apps' synced
   ExternalSecrets just sit unresolved and ArgoCD retries - same self-healing behavior Hetzner
   relies on, not something unique to homelab.

## Adding node-2/3/4 later

Copy the `node-1` pattern: a new `homelab/talos/machine_config/node-N` with its own
hostname/IP/interface locals in `env.hcl`, a new `homelab/talos/apply_config/node-N`, and add the
new node's IP to `access`'s `nodes` list (not `bootstrap_node` - that stays pointed at node-1,
etcd only needs to be bootstrapped once). Each additional node gets its own config published to
the router (`homelab:publish-config` would need a node-selecting variant once there's more than
one) and its own USB stick with the same boot ISO - same process as step 2-4 above, per node.
