# Repository structure and conventions

This repository uses **Terragrunt** to standardize Terraform workflows and environment configuration.

## Structure

- `root.hcl` — global Terragrunt configuration
  - remote state backend configuration (GitLab Terraform State Registry)
  - shared locals (e.g., module source base URL)
- `_common/` — reusable Terragrunt building blocks (HCL snippets)
- `_modules/` — **git-ignored** local working copy of Terraform modules, sourced by path
  (`${get_repo_root()}/_modules/<provider>/<module>`) instead of the published
  `infra/terraform/modules` repo. Not visible in `git status`; a module living only here has no
  other home until it is moved into the published modules repo.
- `infra/` — shared infrastructure components
- `prod-0/`, `prod-1/` — environment-specific configuration (Oracle Cloud, K3s)
- `hetzner/` — environment-specific configuration (Hetzner Cloud, Talos Linux)
- `rbac/` — access control manifests/config

## State naming

Remote state name is derived from the directory path:

- `path_relative_to_include()`
- `/` replaced with `_`

This ensures each Terragrunt directory has its own state.

## Secrets

- Secrets are not stored in git.
- Provide required values via `.env` (see `.env.example`) and environment variables.

## Running

Typical flow:

```bash
cp .env.example .env
# fill secrets in .env

task fmt
DIR=infra/oracle/vcn task plan
DIR=infra/oracle/vcn task apply
```
