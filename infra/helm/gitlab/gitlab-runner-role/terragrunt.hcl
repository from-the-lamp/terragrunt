include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

inputs = {
  helm_chart_name = "role-with-rolebinding"
  helm_chart_version = "0.0.4"
  helm_values_file = <<-EOF
  roles:
    - kind: Role
      name: argocd-access
      namespace: argocd
      rules:
      - apiGroups: ["argoproj.io"]
        resources: ["applications", "applicationsets", "appprojects"]
        verbs: ["get", "list", "watch", "create", "update", "delete"]
      - apiGroups: [""]
        resources: ["configmaps", "secrets", "pods", "pods/portforward", "events"]
        verbs: ["get", "list", "create"]
  roleBindings:
    - kind: RoleBinding
      namespace: argocd
      subjects:
      - kind: ServiceAccount
        name: gitlab-runner
        namespace: gitlab
      roleRef:
        kind: Role
        name: argocd-access
        namespace: 
        apiGroup: rbac.authorization.k8s.io

  EOF
}
