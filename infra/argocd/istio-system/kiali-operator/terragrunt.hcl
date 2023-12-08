include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  gitlab_base_url = local.common_settings.locals.gitlab_base_url
  kiali_openid_client_id = local.common_settings.locals.kiali_openid_client_id
}

dependency "istiod" {
  config_path = "../istiod"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

dependency "kiali-operator-config" {
  config_path = "../kiali-operator-config"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

inputs = {
  dest_cluster_list = [
    {
      cluster = "prod-0"
      domen = "from-the-lamp.com"
    }
  ]
  project = "infra"
  apps = [
    {
      wait = false
      helm_repo_url = "https://kiali.org/helm-charts"
      helm_chart_version = "1.77.0"
      values = <<EOT
      cr:
        create: true
        namespace: istio-system
        spec:
          deployment:
            logger:
              log_level: "trace"
            secret_name: kiali-operator-config
          auth:
            strategy: "openid"
            openid:
              client_id: ${local.kiali_openid_client_id}
              issuer_uri: "https://${local.gitlab_base_url}"
              authorization_endpoint: "https://${local.gitlab_base_url}/oauth/authorize"
              scopes: ["openid", "email"]
              username_claim: "email"
              disable_rbac: true
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
              url: "https://grafana.{{domen}}"
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
      EOT
    },
    {
      app_name = "kiali-gateway"
      helm_chart_name = "istio-gateway"
      helm_chart_version = "0.0.7"
      values = <<EOT
      hosts:
      - kiali.from-the-lamp.com
      external: true
      headers:
        request:
          set:
            X-Forwarded-Port: "443"
      virtualService:
        destination:
          host: kiali
          port: 20001
      EOT
    }
  ]
}
