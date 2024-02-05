include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
}

dependency "runner_token" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/runner_token"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    token = "fake-token"
  }
}

inputs = {
  project = "infra"
  dest_cluster_list = [
    {
      cluster = "in-cluster"
      domen = "from-the-lamp.work"
    }
  ]
  apps = [
    {
      helm_chart_name = "gitlab-runner"
      helm_chart_version = "0.61.0"
      helm_repo_url = "https://charts.gitlab.io"
      values = <<EOT
      runnerToken: ${dependency.runner_token.outputs.token}
      gitlabUrl: "https://gitlab.com"
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
        config: |
          [[runners]]
            name = "Kubernetes Gitlab Runner"
            executor = "kubernetes"
            [runners.kubernetes]
              namespace = "{{.Release.Namespace}}"
              image = "arm64v8/ubuntu:23.04"
              helper_image = "gitlab/gitlab-runner-helper:arm-latest"
              node_selector_overwrite_allowed = ".*"
              service_account = "gitlab-runner-infra"
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
      EOT
    }
  ]
}
