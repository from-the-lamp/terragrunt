terraform {
  source = "${local.modules_url}/${local.module_dir}?tag=${local.module_version}"
}

locals {
  common_settings  = read_terragrunt_config("${get_repo_root()}/root.hcl")
  modules_url      = local.common_settings.locals.private_modules_base_url
  module_dir       = "kubernetes/helm"
  module_version   = "1.0.0"
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
  helm_repo        = "oci://registry.gitlab.com/from-the-lamp/infra/helm-charts"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "helm" {
  kubernetes = {
    host  = "${get_env("${upper(replace(local.env, "-", "_"))}_K8S_HOST")}"
    token = "${get_env("${upper(replace(local.env, "-", "_"))}_K8S_TOKEN")}"
    cluster_ca_certificate = <<EOT
${base64decode(get_env("${upper(replace(local.env, "-", "_"))}_K8S_CERTIFICATE"))}
    EOT
  }
  registries = [
    {
      url      = "${local.helm_repo}"
      # Cross-project pull (infra/helm-charts, not this repo) - root.hcl's
      # helm_repo_user/helm_repo_pass (GITLAB_API_TOKEN), not TF_HTTP_*
      # (the state backend's own auth, gitlab-ci-token/$CI_JOB_TOKEN in CI -
      # scoped to this project only, would be rejected here).
      username = "${local.common_settings.locals.helm_repo_user}"
      password = "${local.common_settings.locals.helm_repo_pass}"
    }
  ]
}
EOF
}

inputs = {
  helm_force_update     = true
  helm_recreate_pods    = true
  helm_repo_url         = local.helm_repo
  helm_chart_name       = basename(get_terragrunt_dir())
  helm_release_name     = basename(get_terragrunt_dir())
  helm_namespace        = basename(dirname(get_terragrunt_dir()))
  helm_create_namespace = true
}
