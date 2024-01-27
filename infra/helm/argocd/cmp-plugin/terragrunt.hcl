include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

inputs = {
  helm_chart_name = "config"
  helm_chart_version = "0.0.5" 
  helm_values_file = <<-EOF
  global:
    secret:
      AVP_TYPE: "vault"
      VAULT_ADDR: "http://vault.vault.svc.cluster.local:8200"
      AVP_AUTH_TYPE: "k8s"
      AVP_K8S_ROLE: "argocd-app"
    env:
      plugin.yaml: |
        ---
        apiVersion: argoproj.io/v1alpha1
        kind: ConfigManagementPlugin
        metadata:
          name: argocd-vault-plugin-helm
        spec:
          allowConcurrency: true
          discover:
            find:
              command:
                - sh
                - "-c"
                - "find . -name 'Chart.yaml' && find . -name 'values.yaml'"
          init:
            command:
              - sh
              - "-c"
              - |
                helm repo add infra https://gitlab.com/api/v4/projects/40582099/packages/helm/stable
                helm dependency build 
          generate:
            command:
              - bash
              - "-c"
              - |
                helm template $ARGOCD_APP_NAME -n $ARGOCD_APP_NAMESPACE -f <(echo "$ARGOCD_ENV_HELM_VALUES") . |
                argocd-vault-plugin generate -s cmp-plugin -
          lockRepo: false
  EOF
}
