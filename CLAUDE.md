# CLAUDE.md

## Commands come from the Taskfile, not from memory or docs

Run `task --list-all` before doing anything. This repo also ships a `mise.toml` pinning the CLI
tools (`terragrunt`, `opentofu`, `kubectl`, `talosctl`, `hcloud`, `jq`) the tasks expect - run
`mise trust` once per clone, then `mise install`, instead of assuming tools are on PATH or
installing them another way. Note: the pinned Terraform-compatible tool is `opentofu` (binary
`tofu`), not `terraform`.

## This is not a build-and-push repo - these commands touch real, live infrastructure

Unlike `docker-images`/`helm-charts`/`terraform-modules`, there's no VERSION/artifact-publish
convention here. `task plan` / `task apply` / `task destroy` / `task unlock` / `task migrate-state`
run `terragrunt` directly against whatever's under `homelab/`, `infra/`, `prod-0/`, `prod-1/` -
real state, real cloud/homelab resources.

**`DIR=<path>` is required, always.** The underlying task has no default for it and runs
`terragrunt <action> --all`: leave `DIR` unset and `task apply`/`task plan`/`task destroy` recurse
over every unit in the entire repo at once - all of `homelab/`, `infra/`, `prod-0/`, `prod-1/`
simultaneously. Always scope it, e.g. `DIR=infra/oracle/vcn task plan`, then
`DIR=infra/oracle/vcn task apply` with the exact same `DIR`. Never run `destroy` without being
certain of the target directory, and treat `unlock`/`migrate-state` as genuinely dangerous - they
exist for real incident/bootstrap scenarios, not routine use.

## `.tasks/homelab.yml` provisions the physical node - read before running anything here

`task homelab:flash` writes a raw disk image to a USB device with `dd` - it has interactive
confirmation built in (retype the device path), but double-check `DEVICE=` against `lsblk`/
`diskutil list` yourself first regardless; this is the kind of command that's trivially
unrecoverable against the wrong target. `homelab:config` dumps real cluster secrets into
`homelab/_generated/config.yaml` - never commit it. `homelab:config-server` opens an unauthenticated
HTTP server on the LAN serving that file - don't leave it running longer than the boot you're doing.
