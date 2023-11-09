include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

dependency "argocd" {
  config_path = "${get_repo_root()}/${local.env}/helm/infra/argo-cd"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  infra_helm_repo_url = local.common_settings.locals.infra_helm_repo_url
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  argocd_apps_version = local.versions.locals.argocd_apps
  base_helm_chart_version = local.versions.locals.base_helm_chart
}

inputs = {
  helm_repo_url = "https://argoproj.github.io/argo-helm"
  helm_chart_name = "argocd-apps"
  helm_release_name = "${basename(get_terragrunt_dir())}-apps"
  helm_chart_version = local.argocd_apps_version
  k8s_namespace = "argocd"
  helm_values_file = <<-EOF
  projects:
  - name: frontend
    namespace: infra
    destinations:
    - name: prod
      namespace: frontend
    - name: prod
      namespace: istio-system
    clusterResourceWhitelist:
    - group: ''
      kind: Namespace
    namespaceResourceWhitelist:
    - group: "*"
      kind: "*"
    - group: cert-manager.io/v1
      kind: Certificate
    sourceNamespaces:
    - infra
    sourceRepos:
      - "!https://gitlab.com/group/from-the-lamp/frontend/**"
      - "https://gitlab.com/api/v4/projects/40582099/packages/helm/stable"
  applications:
  - name: general
    namespace: infra
    project: frontend
    finalizers:
    - resources-finalizer.argocd.argoproj.io
    destination:
      name: prod
      namespace: frontend
    sources:
    - chart: base
      repoURL: ${local.infra_helm_repo_url}
      targetRevision: ${local.base_helm_chart_version}
      helm:
        releaseName: general
        valueFiles:
        - $values/values.yml
        parameters:
        - name: global.image.name
          value: registry.gitlab.com/from-the-lamp/frontend/general
        - name: global.image.tag
          value: latest
    - ref: values
      repoURL: https://gitlab.com/from-the-lamp/frontend/general.git
      targetRevision: main
    syncPolicy:
      automated:
        prune: true 
        selfHeal: true
      managedNamespaceMetadata:
          labels:
            istio-injection: enabled
      syncOptions:
      - CreateNamespace=true
    ignoreDifferences:
    - group: cert-manager.io
      kind: Certificate
      jsonPointers:
      - /spec/duration
      - /spec/renewBefore
  - name: book
    namespace: infra
    project: frontend
    finalizers:
    - resources-finalizer.argocd.argoproj.io
    destination:
      name: prod
      namespace: frontend
    sources:
    - chart: base
      repoURL: ${local.infra_helm_repo_url}
      targetRevision: ${local.base_helm_chart_version}
      helm:
        releaseName: book
        valueFiles:
        - $values/values.yml
        parameters:
        - name: global.image.name
          value: registry.gitlab.com/from-the-lamp/frontend/book
        - name: global.image.tag
          value: latest
    - ref: values
      repoURL: https://gitlab.com/from-the-lamp/frontend/book.git
      targetRevision: main
    syncPolicy:
      automated:
        prune: true 
        selfHeal: true
      managedNamespaceMetadata:
          labels:
            istio-injection: enabled
      syncOptions:
      - CreateNamespace=true
    ignoreDifferences:
    - group: cert-manager.io
      kind: Certificate
      jsonPointers:
      - /spec/duration
      - /spec/renewBefore
  EOF
}
