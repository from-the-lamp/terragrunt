# Repository structure and conventions

This repository uses **Terragrunt** to standardize Terraform workflows and environment configuration.

## Structure

- `root.hcl` — global Terragrunt configuration
  - remote state backend configuration (GitLab Terraform State Registry)
  - shared locals (e.g., module source base URL)
- `_common/` — reusable Terragrunt building blocks (HCL snippets)
- `infra/` — shared infrastructure components
- `prod-0/` — environment-specific configuration (production)
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
