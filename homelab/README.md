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
  output IS what goes on the metal-iso boot media - see the bootstrap steps below.
- `homelab/talos/access` - runs `talos_machine_bootstrap` (the one-time etcd init, same thing
  `talosctl bootstrap` does) and `talos_cluster_kubeconfig` (fetches kubeconfig to
  `./kubeconfig.yaml`). Needs the node already up and configured - satisfied by the metal-iso
  boot, not by Terraform itself.
- `homelab/talos/apply_config/node-1` - re-applies config to an already-bootstrapped node
  (version bumps, patch changes) via `talosctl apply-config`, reviewable through the same
  git-plan/apply flow as every other change in this repo instead of a one-off manual command.

`os_upgrade`/`kubernetes_upgrade` units (Hetzner has both) aren't set up yet - add them the same
way `hetzner/talos/os_upgrade`/`kubernetes_upgrade` are structured once there's an actual Talos
or Kubernetes version bump to do. Not needed to get the node running.

## Bootstrap

1. **Register the schematic and get the installer image.** `env.hcl`'s `talos_extensions`
   (`siderolabs/amd-ucode` for the Ryzen CPU) - confirm the box's actual NIC chipset once you have
   it in hand; some Realtek 2.5GbE parts need their own extension to be recognized at all.

   ```bash
   curl -sS -X POST -H "Content-Type: application/json" \
     -d '{"customization":{"systemExtensions":{"officialExtensions":["siderolabs/amd-ucode"]}}}' \
     https://factory.talos.dev/schematics
   # -> {"id": "<SCHEMATIC_ID>"}
   ```

2. **Generate the cluster secrets and render the machine config - no hardware needed yet:**

   ```bash
   cd homelab/talos/secrets && terragrunt apply
   cd ../machine_config/node-1 && terragrunt apply
   terragrunt output -raw machine_configuration > /tmp/homelab-node-1.yaml
   ```

3. **Build the boot media.** Flash
   `https://factory.talos.dev/image/<SCHEMATIC_ID>/v1.9.0/metal-amd64.iso` to a USB stick, then add
   a second partition/volume on the SAME stick labeled `metal-iso` containing
   `/tmp/homelab-node-1.yaml` (as `config.yaml`) - Talos's `talos.config=metal-iso` mechanism loads
   machine config straight from any block device with that label at first boot, no network or
   manual `apply-config` step needed. The rendered file has real cluster secrets in it - keep the
   USB stick itself as the only copy, don't commit `/tmp/homelab-node-1.yaml` anywhere (this repo
   is public).

4. **Boot the node.** Plug in the USB stick, power on. It installs, applies the config from
   `metal-iso`, and comes up already configured with its static IP - no console interaction.

5. **Bootstrap etcd and fetch kubeconfig:**

   ```bash
   cd homelab/talos/access && terragrunt apply
   # -> ./kubeconfig.yaml
   ```

6. **Install the CNI** (nothing schedules without this - `cluster.network.cni.name: none` in the
   machine config deliberately disables Talos's bundled Flannel):

   ```bash
   KUBECONFIG=homelab/talos/access/kubeconfig.yaml \
     helm install lamp-cilium oci://registry.gitlab.com/from-the-lamp/infra/helm-charts/lamp-cilium \
     --version 0.1.1 -n kube-system
   ```

7. **Install ArgoCD** (same chart Hetzner's Terraform installs via `hetzner/helm/argocd/argocd` -
   see that `terragrunt.hcl` for the full `helm_values`, notably `defaultClusterName: in-cluster`
   and the GitLab OIDC wiring):

   ```bash
   KUBECONFIG=homelab/talos/access/kubeconfig.yaml \
     helm install lamp-argocd oci://registry.gitlab.com/from-the-lamp/infra/helm-charts/lamp-argocd \
     --version 0.0.1 -n argocd --create-namespace -f <values extracted from hetzner's terragrunt.hcl>
   ```

   Then point it at `infra/argo-apps`'s `projects` chart (`platform-lamp-homelab` AppProject +
   ApplicationSet, already committed) the same way Hetzner's root app does.

8. **External Secrets + Vault.** Every app under `apps/homelab/platform` that sets
   `externalSecrets: name: vault` needs the External Secrets Operator (`lamp-external-secrets`,
   same chart as `hetzner/helm/external-secrets/external-secrets`) plus a ClusterSecretStore
   named `vault` pointing at the `vault` app's Service - but `vault` itself is deployed *by*
   ArgoCD from `apps/homelab/platform/vault`, so there's a bootstrap-order dependency (ESO before
   most apps resolve secrets; Vault unsealed before ESO can read from it) that Hetzner's original
   setup presumably solved with some specific sequencing. That exact sequence wasn't
   reverse-engineered here - treat this step as the next thing to work out, not something this
   runbook has already solved.

9. Local storage (`local-path-provisioner`) doesn't need anything before ArgoCD - it's a normal
   `apps/homelab/platform` app with no ExternalSecret dependency, so it can just sync whenever
   ArgoCD gets to it.

## Adding node-2/3/4 later

Copy the `node-1` pattern: a new `homelab/talos/machine_config/node-N` with its own
hostname/IP/interface locals in `env.hcl`, a new `homelab/talos/apply_config/node-N`, and add the
new node's IP to `access`'s `nodes` list (not `bootstrap_node` - that stays pointed at node-1,
etcd only needs to be bootstrapped once). Each additional node gets its own metal-iso USB stick
rendered from its own `machine_config/node-N` output - same process as step 2-4 above, per node.
