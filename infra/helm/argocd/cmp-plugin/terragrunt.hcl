include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/kubernetes/helm.hcl"
}

inputs = {
  helm_chart_name    = "config"
  helm_chart_version = "0.0.5"
  helm_values_file   = <<-EOF
  global:
    secret:
      AVP_TYPE: "vault"
      VAULT_ADDR: "http://vault.vault.svc.cluster.local:8200"
      AVP_AUTH_TYPE: "k8s"
      AVP_K8S_ROLE: "argocd"
    env:
      avp.yaml: |
        ---
        apiVersion: argoproj.io/v1alpha1
        kind: ConfigManagementPlugin
        metadata:
          name: argocd-vault-plugin
        spec:
          lockRepo: false
          allowConcurrency: true
          discover:
            find:
              command:
                - sh
                - "-c"
                - "find . -name '*.yaml' | xargs -I {} grep \"<path\\|avp\\.kubernetes\\.io\" {} | grep ."
          generate:
            command:
              - bash
              - "-c"
              - |
                argocd-vault-plugin generate -s cmp-plugin . 
      avp-helm.yaml: |
        ---
        apiVersion: argoproj.io/v1alpha1
        kind: ConfigManagementPlugin
        metadata:
          name: argocd-vault-plugin-helm
        spec:
          lockRepo: false
          allowConcurrency: true
          discover:
            find:
              command:
                - /bin/bash
                - -c
                - "find . -name 'Chart.yaml' && find . -name 'values.yaml'"
          init:
            command:
              - /bin/sh
              - -c
              - |
                for REPO_URL in $(helm dependency list | tail -n+2 | tr -s '[:space:]' | cut -f3)
                  do
                    helm repo add $(echo -n "$${REPO_URL}" | base64) "$${REPO_URL}"
                done
                helm dependency build
          generate:
            command:
              - /bin/bash
              - -c
              - |
                rendered_templates=$(helm template $${ARGOCD_ENV_HELM_RELEASE_NAME:-$ARGOCD_APP_NAME} -n $ARGOCD_APP_NAMESPACE $${ARGOCD_ENV_HELM_ARGS} -f <(echo "$ARGOCD_ENV_HELM_VALUES") . --include-crds)
                additional_manifest=$${ARGOCD_ENV_ADDITIONAL_MANIFEST}
                if [ -n "$additional_manifest" ]; then
                  echo "$rendered_templates"
                  echo "---"
                  echo "$additional_manifest"
                else
                  echo "$rendered_templates"
                fi | argocd-vault-plugin generate -s cmp-plugin -
  EOF
}
