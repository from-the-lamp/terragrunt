# 🏗️ Infrastructure as Code: Terragrunt & Oracle Cloud

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![Terragrunt](https://img.shields.io/badge/-Terragrunt-blue?style=for-the-badge&logo=terraform&logoColor=white)
![Oracle](https://img.shields.io/badge/Oracle-F80000?style=for-the-badge&logo=oracle&logoColor=white)
![Hetzner](https://img.shields.io/badge/Hetzner-D50C2D?style=for-the-badge&logo=hetzner&logoColor=white)
![K3s](https://img.shields.io/badge/K3s-FF6100?style=for-the-badge&logo=kubernetes&logoColor=white)
![Talos](https://img.shields.io/badge/Talos-FF4B4B?style=for-the-badge&logo=kubernetes&logoColor=white)

A repository for managing infrastructure using **Terragrunt** and **Terraform**. The infrastructure includes **K3s** clusters on **Oracle Cloud Infrastructure (OCI)**, a **Talos Linux** cluster on **Hetzner Cloud**, DNS management via **Cloudflare**, and **GitLab** integration for remote state storage.

---

## 📂 Project Structure

```text
.
├── _common/            # Shared Terragrunt configurations
├── _modules/           # Git-ignored local working copy of Terraform modules (see docs/STRUCTURE.md)
├── infra/              # Infrastructure resource definitions
│   ├── oracle/         # Oracle resources (Networking, K3s, etc.)
│   └── helm/           # Helm chart management via Terraform
├── prod-0/, prod-1/    # Environment-specific configuration (Oracle Cloud, K3s)
├── hetzner/            # Environment-specific configuration (Hetzner Cloud, Talos Linux)
├── rbac/               # Access control settings
├── root.hcl            # Root Terragrunt configuration file
└── Taskfile.yml        # Automation for common tasks
```

---

## 🚀 Quick Start

### 0. Install tooling

```bash
mise install
```

Installs the exact `opentofu`/`terragrunt`/`kubectl`/`talosctl`/`hcloud`/`jq` versions this repo is
tested against (see `mise.toml`) and copies `.env.example` to `.env` if it doesn't exist yet.
`talosctl`'s version is pinned to match `hetzner/env.hcl`'s `talos_version` — a mismatched talosctl
silently fails some RPCs against an older Talos server while others keep working, which is easy to
mistake for flaky infrastructure.

### 1. Oracle Cloud (OCI) Preparation

To interact with the Oracle Cloud API, you need to set up API keys:

1. Go to **Oracle Cloud Console** -> **Identity & Security** -> **Users** -> **User Details**.
2. In the **API Keys** section, click **Add API Key**.
3. Download the private key (`.pem`).
4. Configure your local setup:

```bash
mkdir -p ~/.oci
# Place the downloaded .pem file into ~/.oci
chmod 600 ~/.oci/*.pem
touch ~/.oci/config
chmod 600 ~/.oci/config
```

Example `~/.oci/config` content:
```ini
[lamp-infra]
user=ocid1.user.oc1...
fingerprint=...
tenancy=ocid1.tenancy.oc1...
key_file=~/.oci/your-key.pem
compartment_ocid=ocid1.compartment.oc1...
region=eu-frankfurt-1
```

### 2. Hetzner Cloud + Talos Linux Preparation

The `hetzner/` environment stands up a 3-node Talos Linux cluster where every node is both
control-plane and worker, fronted by a Hetzner Load Balancer. The only prerequisite is a Hetzner
Cloud API token (Project -> Security -> API Tokens, **Read & Write** — the environment creates and
modifies the network, firewall, servers, load balancer, load balancer targets, and the node image
snapshot) exported as `HETZNER_API_TOKEN`.

Hetzner has no official Talos image, so `hetzner/hetzner/talos_image` builds one declaratively on
every apply: it takes the `hcloud`-platform disk image for `talos_version` from
[Image Factory](https://factory.talos.dev) and uploads it as a Hetzner snapshot via the
[`hcloud-talos/imager`](https://github.com/hcloud-talos/terraform-provider-imager) provider — no
manual `hcloud-upload-image` step. `hetzner/env.hcl`'s `talos_extensions` selects which system
extensions are baked in (defaults to `[]`, i.e. no extensions); the Image Factory schematic ID this
maps to is registered live on every apply (never hardcoded — see `_common/hetzner/talos_image.hcl`).

Talos API access for `terraform`/`talosctl` (port 50000-50001) is restricted by
`hetzner/env.hcl`'s `admin_source_ips`; left empty, it auto-detects the current public IP of
whoever runs `terragrunt` (see `_common/hetzner/firewall.hcl`) — set it explicitly (e.g. an
office/VPN CIDR) to override.

`hetzner/talos/access/kubeconfig.yaml` is written automatically (mode 600, git-ignored) by an
`after_hook` on the `hetzner/talos/access` unit every time it's applied — use it directly with
`kubectl --kubeconfig` or `export KUBECONFIG=...`, no manual `terragrunt output` needed.

**The Terraform modules under `_modules/hetzner` and `_modules/talos` are git-ignored and are NOT
published anywhere** (unlike other providers' modules, which live in the separate, published
`infra/terraform/modules` repo referenced by `root.hcl`'s `private_modules_base_url`). They only
exist in a working tree that has them. A fresh `git clone` of this repo **cannot apply the
`hetzner/` environment** until these modules are recreated or copied in from elsewhere — there is
currently no other copy. Publish them to `infra/terraform/modules` (and repoint
`_common/hetzner/*.hcl` / `_common/talos/*.hcl` sources at it) before relying on this environment
from a fresh checkout.

#### Managing a running cluster

`hcloud_server.template` has `lifecycle.ignore_changes = [user_data]` — bumping `talos_version`,
`kubernetes_version`, or any `config_patches` in `hetzner/env.hcl` /
`_common/talos/machine_configuration.hcl` **never** replaces a node by itself; a node VM is only
ever replaced by an explicit `terraform apply -replace=hcloud_server.template`. Ongoing version and
config changes instead go through `talosctl` on the already-running node, one node at a time, via a
chain of `dependency` blocks that only lets node N+1 start once node N's change (and its own health
check) has completed. Terragrunt only resolves that dependency ordering for `run --all` — a
standalone `terragrunt apply` inside a single `node-N` directory has no ordering guarantee at all —
so these **must** be applied with `run --all` scoped to the specific subtree, e.g.:

```bash
cd hetzner/talos/os_upgrade && terragrunt run --all apply
```

Don't run a *wider* `run --all` that also sweeps in unrelated units (e.g. from the repo root or from
`hetzner/talos/` directly, which would mix `os_upgrade`/`apply_config`/`kubernetes_upgrade`/
`secrets`/`access` together).

- **Talos OS version bump** (`talos_version`): `hetzner/talos/os_upgrade/node-1`, `node-2`, `node-3`
  (in that order) call `talosctl upgrade --wait`, which reboots the node into the new OS image in
  place — etcd's data survives, no re-bootstrap needed — then poll `talosctl service etcd` until
  healthy before letting the next node start.
- **Kubernetes version bump** (`kubernetes_version`): `hetzner/talos/kubernetes_upgrade` (a single
  unit) calls `talosctl upgrade-k8s --to`, which orchestrates every node in the cluster on its own.
- **Any other `config_patches` change** (e.g. a new system extension, a network tweak):
  `hetzner/talos/apply_config/node-1`, `node-2`, `node-3` (in that order) call
  `talosctl apply-config --mode=auto` against the running node — no VM replacement — then poll
  `talosctl service etcd` until healthy before letting the next node start, the same way the OS
  upgrade path does.

All three need `talosctl` on the machine running terraform — `mise install` provides the version
pinned to match `talos_version` (see below).

**Graceful etcd leave on node destroy**: `_modules/hetzner/server`'s
`terraform_data.talos_admin_config` runs `talosctl etcd leave` in a destroy-time provisioner before
Hetzner tears down the VM, so a deliberate `-replace` (or a future scale-down) doesn't leave a stale
etcd member behind eating into quorum.

#### Known gotchas

- **`_common/talos/machine_configuration.hcl` sets `cluster.network.cni.name = "none"`** because
  Talos's bundled Flannel CNI was found to deploy alongside Cilium by default and broke pod routing
  to the Hetzner metadata service (169.254.169.254), crash-looping `hcloud-csi`. Cilium is installed
  separately via the `hetzner/helm/kube-system/cilium` unit — don't remove this setting as a
  "redundant default."
- `hetzner/talos/access`'s `talos_machine_bootstrap`/`talos_cluster_kubeconfig` resources use
  `lifecycle.replace_triggered_by` on the bootstrap node's `hcloud_server` ID, so they correctly
  re-run after a node replacement even if Hetzner reassigns the same IP. If a bootstrap ever fails
  with `AlreadyExists: etcd data directory is not empty` (Talos correctly refusing to re-bootstrap
  an already-initialized node), reconcile state with
  `terragrunt import talos_machine_bootstrap.template machine_bootstrap` followed by a normal
  `apply` (which safely recreates `talos_cluster_kubeconfig`, a read-only operation).
- There is currently no mechanism to add a 4th (or 5th) node beyond copying an existing
  `hetzner/hetzner/nodes/node-N` directory and wiring the new node into
  `hetzner/hetzner/load_balancer/targets` and `hetzner/talos/access`'s `nodes` list by hand.

### 3. Environment Variables Setup

Create a `.env` file based on the example:

```bash
cp .env.example .env
# Edit .env and add your tokens/keys
```

Working with state in GitLab requires `TF_HTTP_PASSWORD` (Personal Access Token).

---

## 🛠️ Taskfile Usage

The project uses [Taskfile](https://taskfile.dev) to simplify command execution.

| Command | Description |
| :--- | :--- |
| `task apply DIR=<path>` | Run `terragrunt apply` in the specified directory |
| `task plan DIR=<path>` | Review change plan |
| `task fmt` | Format all HCL files |
| `task cleanup` | Remove temporary files and Terragrunt cache |
| `task list-all` | Show all available commands |

**Example:** Apply configuration for K3s:
```bash
DIR=infra/oracle/k3s task apply
```

---

## 🔐 State Management

The Terraform State is stored remotely in the **GitLab Terraform State Registry**. The backend configuration is automatically generated by `root.hcl`.

---

## 📜 License

This project is distributed under the [Apache License 2.0](LICENSE).