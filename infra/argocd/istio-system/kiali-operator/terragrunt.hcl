include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  infra_zone = local.environment_vars.locals.infra_zone
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  versions = read_terragrunt_config("${get_repo_root()}/_common/versions.hcl")
  istio_gateway_version = local.versions.locals.istio_gateway
  kiali_operator_version = local.versions.locals.kiali_operator
  gitlab_base_url = local.common_settings.locals.gitlab_base_url
}

dependency "istiod" {
  config_path = "../istiod"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

inputs = {
  project = "infra"
  ignore_difference = [
    {
      group = "cert-manager.io"
      kind = "Certificate"
      json_pointers = [
        "/spec/duration",
        "/spec/renewBefore"
      ]
      jq_path_expressions = []
    }
  ]
  apps = [
    {
      wait = false
      helm_repo_url = "https://kiali.org/helm-charts"
      helm_chart_version = local.kiali_operator_version
      values = <<EOT
      cr:
        create: true
        namespace: istio-system
        spec:
          external_services:
            istio:
              enabled: true
              component_status:
                components:
                - app_label: "istiod"
                  is_core: true
                  is_proxy: false
                - app_label: "ingressgateway"
                  is_core: true
                  is_proxy: true
                  namespace: istio-system
            tracing:
              enabled: false
            prometheus:
              url: http://kube-prometheus-stack-prometheus.monitoring:9090
            grafana:
              enabled: true
              auth:
                type: "bearer"
                use_kiali_token: false
              in_cluster_url: http://kube-prometheus-stack-grafana.monitoring:80
              url: https://grafana.${local.infra_zone}
              dashboards:
              - name: "Istio Service Dashboard"
                variables:
                  namespace: "var-namespace"
                  service: "var-service"
              - name: "Istio Workload Dashboard"
                variables:
                  namespace: "var-namespace"
                  workload: "var-workload"
              - name: "Istio Mesh Dashboard"
              - name: "Istio Control Plane Dashboard"
              - name: "Istio Performance Dashboard"
              - name: "Istio Wasm Extension Dashboard"
        #   auth:
        #     strategy: "openid"
        #     openid:
        #       client_id: 34abbfae423ab9f382c578bd1953ea5b68dd055af9cc349dbb748c5def2cb1bd
        #       oidc-secret:
        #         secret: kiali-openid-secret-env
        #         key: oidc-secret
        #       issuer_uri: "https://${local.gitlab_base_url}"
        #       authorization_endpoint: "https://${local.gitlab_base_url}/oauth/authorize"
        #       scopes: ["openid", "email", "profile"]
        #       username_claim: "email"
        #       disable_rbac: true
      EOT
    },
    {
      app_name = "kiali-gateway"
      helm_chart_name = "istio-gateway"
      helm_chart_version = local.istio_gateway_version
      values = <<EOT
      hosts:
      - kiali.from-the-lamp.com
      external: true
      virtualService:
        destination:
          host: kiali
          port: 20001
      EOT
    }
  ]
}
