include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

inputs = {
  helm_chart_name = "role-with-rolebinding"
  helm_chart_version = "0.0.3" 
  helm_values_file = <<-EOF
  roles:
    - kind: ClusterRole
      name: argocd-access
      namespace: default
      rules:
      - apiGroups: ["argoproj.io"]
        resources: ["applications", "applicationsets", "appprojects"]
        verbs: ["get", "list", "watch", "create", "update", "delete"]
      - apiGroups: [""]
        resources: ["configmaps", "secrets"]
        verbs: ["get", "list"]
  roleBindings:
    - kind: ClusterRoleBinding
      subjects:
      - kind: ServiceAccount
        name: gitlab-runner-infra
        namespace: gitlab
      roleRef:
        kind: ClusterRole
        name: argocd-access
        apiGroup: rbac.authorization.k8s.io
  EOF
}
