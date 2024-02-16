include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/k8s/helm.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  infra_helm_repo_url = local.common_settings.locals.infra_helm_repo_url
  openid_client_id_argocd = local.common_settings.locals.openid_client_id_argocd
}

dependency "infra_variables" {
  config_path = "${get_repo_root()}/${local.env}/gitlab/infra_variables"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  mock_outputs = {
    variables = {
      cloudflare_api_token = "fake-token"
      gitlab_openid_secret = "fake-secret"
    }
  }
}

dependency "cmp-plugin" {
  config_path = "../cmp-plugin"
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

dependency "oci_cloud_controller_manager" {
  config_path = "${get_repo_root()}/${local.env}/helm/kube-system/oci-cloud-controller-manager"
  mock_outputs_allowed_terraform_commands = ["apply" ,"plan", "validate", "output", "init", "destroy"]
  skip_outputs = true
}

inputs = {
  helm_repo_url = "https://argoproj.github.io/argo-helm"
  helm_chart_name = "argo-cd"
  helm_chart_version = "6.0.6"
  helm_set_sensitive = {
    "configs.secret.gitlabSecret" = dependency.infra_variables.outputs.variables.openid_client_secret_argocd
  }
  helm_values_file = <<-EOF
  env:
    ARGOCD_K8S_CLIENT_QPS: 300
  controller:
    args:
      appResyncPeriod: "180"
  repoServer:
    volumes:
      - configMap:
          name: cmp-plugin
        name: cmp-plugin
      - name: custom-tools
        emptyDir: {}
      - name: tmp-dir
        emptyDir: {}
    initContainers:
    - name: download-tools
      image: registry.access.redhat.com/ubi8
      env:
        - name: ARCH
          value: arm64
        - name: AVP_VERSION
          value: 1.17.0
        - name: ENVSUBST_VERSION
          value: 1.4.2
      command: [sh, -c]
      args:
        - >-
          curl -L https://github.com/argoproj-labs/argocd-vault-plugin/releases/download/v$(AVP_VERSION)/argocd-vault-plugin_$(AVP_VERSION)_linux_$(ARCH) -o argocd-vault-plugin &&
          chmod +x argocd-vault-plugin &&
          mv argocd-vault-plugin /custom-tools/
        - >-
          curl -L https://github.com/a8m/envsubst/releases/download/v$(ENVSUBST_VERSION)/envsubst-Linux-$(ARCH) -o envsubst &&
          chmod +x envsubst &&
          mv envsubst /custom-tools/
      volumeMounts:
        - mountPath: /custom-tools
          name: custom-tools
    extraContainers:
      - name: avp-helm
        command: [/var/run/argocd/argocd-cmp-server]
        image: quay.io/argoproj/argocd:v2.4.8
        securityContext:
          runAsNonRoot: true
          runAsUser: 999
        volumeMounts:
          - mountPath: /var/run/argocd
            name: var-files
          - mountPath: /home/argocd/cmp-server/plugins
            name: plugins
          - mountPath: /tmp
            name: tmp-dir
          - mountPath: /home/argocd/cmp-server/config
            name: cmp-plugin
          - name: custom-tools
            subPath: argocd-vault-plugin
            mountPath: /usr/local/bin/argocd-vault-plugin
  configs:
    cm:
      url: https://argocd.from-the-lamp.work
      admin.enabled: "false"
      exec.enabled: true
      accounts.gitlab-ci-user: apiKey
      accounts.iac: apiKey
      application.resourceTrackingMethod: annotation
      dex:
        env:
         - name: ARGO_WORKFLOWS_SSO_CLIENT_SECRET
           valueFrom:
             secretKeyRef:
               name: argo-workflows-sso
               key: client-secret
      dex.config: |
          connectors:
          - type: gitlab
            id: ArgoCD
            name: GitLab
            useLoginAsID: false
            config:
              baseURL: https://gitlab.com
              redirectURI: https://argocd.from-the-lamp.work/api/dex/callback
              clientID: ${local.openid_client_id_argocd}
              clientSecret: $webhook.gitlab.secret
              useLoginAsID: false
          staticClients:
            - id: argo-workflows-sso
              name: Argo Workflow
              redirectURIs:
                - https://workflow.from-the-lamp.work/oauth2/callback
              secretEnv: ARGO_WORKFLOWS_SSO_CLIENT_SECRET
      resource.exclusions: |
        - apiGroups:
          - "*"
          kinds:
          - ProviderConfigUsages
      resource.customizations: |
        "*.upbound.io/*":
          health.lua: |
            health_status = {
              status = "Progressing",
              message = "Provisioning ..."
            }
            local function contains (table, val)
              for i, v in ipairs(table) do
                if v == val then
                  return true
                end
              end
              return false
            end
            local has_no_status = {
              "ProviderConfig",
              "ProviderConfigUsage"
            }
            if obj.status == nil and contains(has_no_status, obj.kind) then
              health_status.status = "Healthy"
              health_status.message = "Resource is up-to-date."
              return health_status
            end
            if obj.status == nil or obj.status.conditions == nil then
              if obj.kind == "ProviderConfig" and obj.status.users ~= nil then
                health_status.status = "Healthy"
                health_status.message = "Resource is in use."
                return health_status
              end
              return health_status
            end
            for i, condition in ipairs(obj.status.conditions) do
              if condition.type == "LastAsyncOperation" then
                if condition.status == "False" then
                  health_status.status = "Degraded"
                  health_status.message = condition.message
                  return health_status
                end
              end
              if condition.type == "Synced" then
                if condition.status == "False" then
                  health_status.status = "Degraded"
                  health_status.message = condition.message
                  return health_status
                end
              end
              if condition.type == "Ready" then
                if condition.status == "True" then
                  health_status.status = "Healthy"
                  health_status.message = "Resource is up-to-date."
                  return health_status
                end
              end
            end
            return health_status
        "*.crossplane.io/*":
          health.lua: |
            health_status = {
              status = "Progressing",
              message = "Provisioning ..."
            }
            local function contains (table, val)
              for i, v in ipairs(table) do
                if v == val then
                  return true
                end
              end
              return false
            end
            local has_no_status = {
              "Composition",
              "CompositionRevision",
              "DeploymentRuntimeConfig",
              "ControllerConfig"
            }
            if obj.status == nil and contains(has_no_status, obj.kind) then
                health_status.status = "Healthy"
                health_status.message = "Resource is up-to-date."
              return health_status
            end
            if obj.status == nil or obj.status.conditions == nil then
              return health_status
            end
            for i, condition in ipairs(obj.status.conditions) do
              if condition.type == "LastAsyncOperation" then
                if condition.status == "False" then
                  health_status.status = "Degraded"
                  health_status.message = condition.message
                  return health_status
                end
              end
              if condition.type == "Synced" then
                if condition.status == "False" then
                  health_status.status = "Degraded"
                  health_status.message = condition.message
                  return health_status
                end
              end
              if contains({"Ready", "Healthy", "Offered", "Established"}, condition.type) then
                if condition.status == "True" then
                  health_status.status = "Healthy"
                  health_status.message = "Resource is up-to-date."
                  return health_status
                end
              end
            end
            return health_status 
    params:
      server.insecure: true
      dexserver.disable.tls: true
      applicationsetcontroller.enable.progressive.syncs: true
    rbac:
      policy.default: role:readonly
      policy.csv: |
        p, role:release-admin, applications, *, */*, allow
        p, role:release-admin, clusters, get, *, allow
        p, role:release-admin, repositories, get, *, allow
        p, role:release-admin, repositories, create, *, allow
        p, role:release-admin, repositories, update, *, allow
        p, role:release-admin, repositories, delete, *, allow
        g, from-the-lamp, role:admin
        g, iac, role:admin
        g, gitlab-ci-user, role:release-admin
        g, frontend, role:release-admin
        g, backend, role:release-admin
  EOF
}
