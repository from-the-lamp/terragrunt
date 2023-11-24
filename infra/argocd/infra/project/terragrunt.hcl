include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/project.hcl"
}

inputs = {
  destinations = [
    {
      name = "*"
      namespace = basename(dirname(get_terragrunt_dir()))
    },
    {
      name = "*"
      namespace = "istio-system"
    },
    {
      name = "*"
      namespace = "kube-system"
    },
    {
      name = "*"
      namespace = "monitoring"
    }
  ]
  cluster_resource_whitelist = [
    {
      group = ""
      kind = "Namespace"
    },
    {
      group = "rbac.authorization.k8s.io"
      kind = "ClusterRole"
    },
    {
      group = "rbac.authorization.k8s.io"
      kind = "ClusterRoleBinding"
    },
    {
      group = "pkg.crossplane.io"
      kind = "Provider"
    },
    {
      group = "pkg.crossplane.io"
      kind = "ControllerConfig"
    },
    {
      group = "apiextensions.k8s.io"
      kind = "CustomResourceDefinition"
    },
    {
      group = "admissionregistration.k8s.io"
      kind = "MutatingWebhookConfiguration"
    },
    {
      group = "admissionregistration.k8s.io"
      kind = "ValidatingWebhookConfiguration"
    },
    {
      group = "tf.upbound.io"
      kind = "ProviderConfig"
    },
    {
      group = "tf.upbound.io"
      kind = "Workspace"
    }
  ]
}
