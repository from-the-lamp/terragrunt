# homelab

Single-node bare-metal Talos cluster (UM890 Pro mini PC, 64GB RAM), reachable only over
Tailscale - no public Load Balancer, no cloud provider. See `apps/homelab/platform` in
`infra/argo-apps` for the GitOps side (forked from `apps/hetzner-infra/platform`).

Unlike `hetzner/`/`prod-0/`/`prod-1/`, this directory is **not** a Terragrunt environment -
there's no cloud resource to provision (the node is physical hardware you flash and plug in,
not something `terraform apply` creates). It's just `controlplane.patch.yaml` plus this runbook.
If a real need for Terraform-managed bare-metal provisioning shows up later (PXE boot, BMC/IPMI
automation, etc.), that's a separate, bigger piece of work - don't assume this README implies it.

## Before you start

Edit every `PLACEHOLDER` in `controlplane.patch.yaml`: interface name, static IP, gateway, LAN
subnet. Also double-check the CIDR collision risk flagged in that file and in
`apps/homelab/platform` (search that tree for "172.24"/"172.25") - verify in the Tailscale admin
console (Machines -> routes) that nothing else in the tailnet already advertises those ranges.

## Bootstrap

1. **Register the schematic and get the installer image.** Same extensions as Hetzner
   (`hetzner/env.hcl`'s `talos_extensions`, currently `[]`) plus `siderolabs/amd-ucode` for the
   UM890's Ryzen CPU - confirm the box's actual NIC chipset once you have it in hand; some
   Realtek 2.5GbE parts need their own extension (e.g. `siderolabs/realtek-firmware`) to be
   recognized by the installer at all.

   ```bash
   curl -sS -X POST -H "Content-Type: application/json" \
     -d '{"customization":{"systemExtensions":{"officialExtensions":["siderolabs/amd-ucode"]}}}' \
     https://factory.talos.dev/schematics
   # -> {"id": "<SCHEMATIC_ID>"}
   ```

   Flash `https://factory.talos.dev/image/<SCHEMATIC_ID>/v1.9.0/metal-amd64.iso` to a USB stick
   (`hcloud-amd64.raw.xz` is the Hetzner-specific variant - `metal-amd64` is the bare-metal one),
   boot the mini PC from it, and it comes up in Talos's maintenance mode.

2. **Generate and apply the machine config.**

   ```bash
   talosctl gen config homelab https://<THE_NODE_STATIC_IP>:6443 \
     --config-patch @controlplane.patch.yaml \
     --output-dir ./_generated
   talosctl apply-config --insecure -n <THE_NODE_STATIC_IP> -f ./_generated/controlplane.yaml
   talosctl bootstrap -n <THE_NODE_STATIC_IP> -e <THE_NODE_STATIC_IP> \
     --talosconfig ./_generated/talosconfig
   talosctl kubeconfig -n <THE_NODE_STATIC_IP> -e <THE_NODE_STATIC_IP> \
     --talosconfig ./_generated/talosconfig
   ```

3. **Install the CNI** (nothing schedules without this - `cluster.network.cni.name: none` in the
   patch deliberately disables Talos's bundled Flannel):

   ```bash
   helm install lamp-cilium oci://registry.gitlab.com/from-the-lamp/infra/helm-charts/lamp-cilium \
     --version 0.1.1 -n kube-system
   ```

4. **Install ArgoCD** (same chart Hetzner's Terraform installs via `hetzner/helm/argocd/argocd` -
   see that `terragrunt.hcl` for the full `helm_values`, notably `defaultClusterName: in-cluster`
   and the GitLab OIDC wiring):

   ```bash
   helm install lamp-argocd oci://registry.gitlab.com/from-the-lamp/infra/helm-charts/lamp-argocd \
     --version 0.0.1 -n argocd --create-namespace -f <values extracted from hetzner's terragrunt.hcl>
   ```

   Then point it at `infra/argo-apps`'s `projects` chart (`platform-lamp-homelab` AppProject +
   ApplicationSet, already committed) the same way Hetzner's root app does.

5. **External Secrets + Vault.** Every app under `apps/homelab/platform` that sets
   `externalSecrets: name: vault` needs the External Secrets Operator (`lamp-external-secrets`,
   same chart as `hetzner/helm/external-secrets/external-secrets`) plus a ClusterSecretStore
   named `vault` pointing at the `vault` app's Service - but `vault` itself is deployed *by*
   ArgoCD from `apps/homelab/platform/vault`, so there's a bootstrap-order dependency (ESO before
   most apps resolve secrets; Vault unsealed before ESO can read from it) that Hetzner's original
   setup presumably solved with some specific sequencing. That exact sequence wasn't
   reverse-engineered here - treat this step as the next thing to work out, not something this
   runbook has already solved.

6. Local storage (`local-path-provisioner`) doesn't need anything before ArgoCD - it's a normal
   `apps/homelab/platform` app with no ExternalSecret dependency, so it can just sync whenever
   ArgoCD gets to it.
