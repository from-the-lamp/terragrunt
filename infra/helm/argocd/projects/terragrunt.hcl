include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/kubernetes/helm.hcl"
}

dependency "argocd" {
  config_path                             = "../argocd"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs                            = true
}

inputs = {
  helm_chart_name    = "argocd-apps"
  helm_repo_url      = "https://argoproj.github.io/argo-helm"
  helm_chart_version = "1.6.1"
  helm_values_file   = <<-EOF
  projects:
  - name: infra
    namespace: argocd
    sourceRepos:
    - "*"
    destinations:
    - name: "*"
      namespace: "*"
    clusterResourceWhitelist:
    - group: ""
      kind: Namespace
    - group: "rbac.authorization.k8s.io"
      kind: ClusterRole
    - group: "rbac.authorization.k8s.io"
      kind: ClusterRoleBinding
    - group: "pkg.crossplane.io"
      kind: Provider
    - group: "pkg.crossplane.io"
      kind: ControllerConfig
    - group: "apiextensions.k8s.io"
      kind: CustomResourceDefinition
    - group: "admissionregistration.k8s.io"
      kind: MutatingWebhookConfiguration
    - group: "admissionregistration.k8s.io"
      kind: ValidatingWebhookConfiguration
    - group: "tf.upbound.io"
      kind: ProviderConfig
    - group: "tf.upbound.io"
      kind: Workspace
    - group: "scheduling.k8s.io"
      kind: PriorityClass
    - group: "apiregistration.k8s.io"
      kind: APIService
    - group: "storage.k8s.io"
      kind: StorageClass
    - group: "cert-manager.io"
      kind: ClusterIssuer
    - group: "vault.upbound.io"
      kind: StoreConfig
    - group: "vault.upbound.io"
      kind: ProviderConfig
    - group: "cert-manager.k8s.cloudflare.com"
      kind: ClusterOriginIssuer
    - group: "external-secrets.io"
      kind: ClusterSecretStore
    - group: "snapshot.storage.k8s.io"
      kind: VolumeSnapshotClass
    namespaceResourceWhitelist:
    - group: "*"
      kind: "*"
    - group: "cert-manager.io/v1"
      kind: Certificate
  - name: frontend
    namespace: argocd
    sourceRepos:
    - "*"
    destinations:
    - name: "*"
      namespace: "*"
    clusterResourceWhitelist:
    - group: ""
      kind: Namespace
    - group: "tf.upbound.io"
      kind: ProviderConfig
    - group: "tf.upbound.io"
      kind: Workspace
    namespaceResourceWhitelist:
    - group: "*"
      kind: "*"
    - group: "cert-manager.io/v1"
      kind: Certificate
  - name: backend
    namespace: argocd
    sourceRepos:
    - "*"
    destinations:
    - name: "*"
      namespace: "*"
    clusterResourceWhitelist:
    - group: ""
      kind: Namespace
    - group: "tf.upbound.io"
      kind: ProviderConfig
    - group: "tf.upbound.io"
      kind: Workspace
    namespaceResourceWhitelist:
    - group: "*"
      kind: "*"
    - group: "cert-manager.io/v1"
      kind: Certificate
  EOF
}
