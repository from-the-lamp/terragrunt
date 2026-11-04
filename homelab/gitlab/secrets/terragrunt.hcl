include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/vault/secrets_managed.hcl"
}

dependency "helm_charts" {
  config_path                             = "../projects/helm-charts/sa/developer"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    token = "fake-token-helm-charts"
  }
}

dependency "argo_apps" {
  config_path                             = "../projects/argo-apps/sa/developer"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    token = "fake-token-argo-apps"
  }
}

dependency "docker_images" {
  config_path                             = "../projects/docker-images/sa/developer"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    token = "fake-token-docker-images"
  }
}

dependency "terraform_modules" {
  config_path                             = "../projects/terraform-modules/sa/developer"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    token = "fake-token-terraform-modules"
  }
}

dependency "terragrunt" {
  config_path                             = "../projects/terragrunt/sa/developer"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    token = "fake-token-terragrunt"
  }
}

inputs = {
  path        = "platform"
  secret_path = "kelos/gitlab-bot-tokens"
  data = {
    "helm-charts"       = dependency.helm_charts.outputs.token
    "argo-apps"         = dependency.argo_apps.outputs.token
    "docker-images"     = dependency.docker_images.outputs.token
    "terraform-modules" = dependency.terraform_modules.outputs.token
    "terragrunt"        = dependency.terragrunt.outputs.token
  }
}
