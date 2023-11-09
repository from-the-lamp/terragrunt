include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  versions         = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  gateway          = local.versions.locals.gateway
  gitlab_runner    = local.versions.locals.gitlab_runner
  common_settings  = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  helm_repo_url    = local.common_settings.locals.infra_helm_repo_url
  helm_repo_user   = local.common_settings.locals.helm_repo_user
  helm_repo_pass   = local.common_settings.locals.helm_repo_pass
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env              = local.environment_vars.locals.environment
  infra_zone       = local.environment_vars.locals.infra_zone
  gitlab_base_url  = local.common_settings.locals.gitlab_base_url
}

dependency "cert-manager" {
  config_path = "../../istio-system/cert-manager"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

dependency "argo-cd" {
  config_path = "../argo-cd"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

dependency "runner_token" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/groups/from-the-lamp/gitlab_user_runner"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    token = "fake-token"
  }
}

inputs = {
  helm_repo_url = "https://charts.gitlab.io"
  helm_chart_version = local.gitlab_runner
  helm_set_sensitive = {
    "runnerRegistrationToken" = dependency.runner_token.outputs.token
  }
  helm_values_file = <<-EOF
  gitlabUrl: "https://${local.gitlab_base_url}"
  concurrent: "5"
  nodeSelector:
    node-role: runner
  resources:
    limits:
      memory: 4000Mi
      cpu: 2000m
    requests:
      memory: 128Mi
      cpu: 100m
  runners:
    tags: "k8s-arm-default"
    config: |
      [[runners]]
        name = "Kubernetes Gitlab Runner"
        executor = "kubernetes"
        [runners.kubernetes]
          namespace = "{{.Release.Namespace}}"
          image = "arm64v8/ubuntu:22.04"
          helper_image = "gitlab/gitlab-runner-helper:arm-latest"
  rbac:
    create: true
    rules:
    - apiGroups: [""]
      resources: ["pods"]
      verbs: ["list", "get", "watch", "create", "delete"]
    - apiGroups: [""]
      resources: ["pods/exec"]
      verbs: ["create"]
    - apiGroups: [""]
      resources: ["pods/log"]
      verbs: ["get"]
    - apiGroups: [""]
      resources: ["pods/attach"]
      verbs: ["list", "get", "create", "delete", "update"]
    - apiGroups: [""]
      resources: ["secrets"]
      verbs: ["list", "get", "create", "delete", "update"]
    - apiGroups: [""]
      resources: ["configmaps"]
      verbs: ["list", "get", "create", "delete", "update"]
  EOF
}
