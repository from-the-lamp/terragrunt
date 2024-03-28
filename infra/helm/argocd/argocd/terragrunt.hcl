include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/kubernetes/helm.hcl"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env = local.environment_vars.locals.environment
  common_settings = read_terragrunt_config("${get_repo_root()}/terragrunt.hcl")
  infra_helm_repo_url = local.common_settings.locals.infra_helm_repo_url
  openid_client_id_argocd = local.common_settings.locals.openid_client_id_argocd
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
  helm_chart_version = "6.7.1"
  helm_set_sensitive = {
    "configs.secret.gitlabSecret" = get_env("OPENID_CLIENT_SECRET_ARGOCD")
  }
  helm_values_file = <<-EOF
  global:
    nodeSelector:
      node-role: worker
    domain: argocd.from-the-lamp.work
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
    rbac:
    - apiGroups:
      - ""
      resources:
      - secrets
      verbs:
      - get
      - list
      - watch
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
      - name: avp
        command: [/var/run/argocd/argocd-cmp-server]
        image: quay.io/argoproj/argocd:v2.10.1
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
          - mountPath: /home/argocd/cmp-server/config/plugin.yaml
            subPath: avp.yaml
            name: cmp-plugin
          - name: custom-tools
            subPath: argocd-vault-plugin
            mountPath: /usr/local/bin/argocd-vault-plugin
      - name: avp-helm
        command: [/var/run/argocd/argocd-cmp-server]
        image: quay.io/argoproj/argocd:v2.10.1
        securityContext:
          runAsNonRoot: true
          runAsUser: 999
        env:
        - name: HELM_CACHE_HOME
          value: /helm-working-dir
        - name: HELM_CONFIG_HOME
          value: /helm-working-dir
        - name: HELM_DATA_HOME
          value: /helm-working-dir
        volumeMounts:
          - mountPath: /var/run/argocd
            name: var-files
          - mountPath: /home/argocd/cmp-server/plugins
            name: plugins
          - mountPath: /tmp
            name: tmp-dir
          - mountPath: /home/argocd/cmp-server/config/plugin.yaml
            subPath: avp-helm.yaml
            name: cmp-plugin
          - name: custom-tools
            subPath: argocd-vault-plugin
            mountPath: /usr/local/bin/argocd-vault-plugin
          - name: helm-working-dir
            mountPath: /helm-working-dir
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
        PersistentVolumeClaim:
          health.lua: |
            hs = {}
            if obj.status ~= nil then
              if obj.status.phase ~= nil then
                if obj.status.phase == "Pending" then
                  hs.status = "Healthy"
                  hs.message = obj.status.phase
                  return hs
                end
                if obj.status.phase == "Bound" then
                  hs.status = "Healthy"
                  hs.message = obj.status.phase
                  return hs
                end
              end
            end
            hs.status = "Progressing"
            hs.message = "Waiting for certificate"
            return hs
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
  notifications:
    secret:
      items:
        slack-token: ${get_env("SLACK_TOKEN")}
    notifiers:
      service.slack: |
        token: $slack-token
    subscriptions:
      - recipients:
        - slack:devops
        triggers:
        - on-sync-failed
        - on-sync-status-unknown
    templates: 
      template.app-created: |
        email:
          subject: Application {{.app.metadata.name}} has been created.
        message: Application {{.app.metadata.name}} has been created.
        teams:
          title: Application {{.app.metadata.name}} has been created.
      template.app-deleted: |
        email:
          subject: Application {{.app.metadata.name}} has been deleted.
        message: Application {{.app.metadata.name}} has been deleted.
        teams:
          title: Application {{.app.metadata.name}} has been deleted.
      template.app-deployed: |
        email:
          subject: New version of an application {{.app.metadata.name}} is up and running.
        message: |
          {{if eq .serviceType "slack"}}:white_check_mark:{{end}} Application {{.app.metadata.name}} is now running new version of deployments manifests.
        slack:
          attachments: |
            [{
              "title": "{{ .app.metadata.name}}",
              "title_link":"{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
              "color": "#18be52",
              "fields": [
              {
                "title": "Sync Status",
                "value": "{{.app.status.sync.status}}",
                "short": true
              },
              {
                "title": "Repository",
                "value": "{{.app.spec.source.repoURL}}",
                "short": true
              },
              {
                "title": "Revision",
                "value": "{{.app.status.sync.revision}}",
                "short": true
              }
              {{range $index, $c := .app.status.conditions}}
              ,
              {
                "title": "{{$c.type}}",
                "value": "{{$c.message}}",
                "short": true
              }
              {{end}}
              ]
            }]
          deliveryPolicy: Post
          groupingKey: ""
          notifyBroadcast: false
        teams:
          facts: |
            [{
              "name": "Sync Status",
              "value": "{{.app.status.sync.status}}"
            },
            {
              "name": "Repository",
              "value": "{{.app.spec.source.repoURL}}"
            },
            {
              "name": "Revision",
              "value": "{{.app.status.sync.revision}}"
            }
            {{range $index, $c := .app.status.conditions}}
              ,
              {
                "name": "{{$c.type}}",
                "value": "{{$c.message}}"
              }
            {{end}}
            ]
          potentialAction: |-
            [{
              "@type":"OpenUri",
              "name":"Operation Application",
              "targets":[{
                "os":"default",
                "uri":"{{.context.argocdUrl}}/applications/{{.app.metadata.name}}"
              }]
            },
            {
              "@type":"OpenUri",
              "name":"Open Repository",
              "targets":[{
                "os":"default",
                "uri":"{{.app.spec.source.repoURL | call .repo.RepoURLToHTTPS}}"
              }]
            }]
          themeColor: '#000080'
          title: New version of an application {{.app.metadata.name}} is up and running.
      template.app-health-degraded: |
        email:
          subject: Application {{.app.metadata.name}} has degraded.
        message: |
          {{if eq .serviceType "slack"}}:exclamation:{{end}} Application {{.app.metadata.name}} has degraded.
          Application details: {{.context.argocdUrl}}/applications/{{.app.metadata.name}}.
        slack:
          attachments: |
            [{
              "title": "{{ .app.metadata.name}}",
              "title_link": "{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
              "color": "#f4c030",
              "fields": [
              {
                "title": "Health Status",
                "value": "{{.app.status.health.status}}",
                "short": true
              },
              {
                "title": "Repository",
                "value": "{{.app.spec.source.repoURL}}",
                "short": true
              }
              {{range $index, $c := .app.status.conditions}}
              ,
              {
                "title": "{{$c.type}}",
                "value": "{{$c.message}}",
                "short": true
              }
              {{end}}
              ]
            }]
          deliveryPolicy: Post
          groupingKey: ""
          notifyBroadcast: false
        teams:
          facts: |
            [{
              "name": "Health Status",
              "value": "{{.app.status.health.status}}"
            },
            {
              "name": "Repository",
              "value": "{{.app.spec.source.repoURL}}"
            }
            {{range $index, $c := .app.status.conditions}}
              ,
              {
                "name": "{{$c.type}}",
                "value": "{{$c.message}}"
              }
            {{end}}
            ]
          potentialAction: |
            [{
              "@type":"OpenUri",
              "name":"Open Application",
              "targets":[{
                "os":"default",
                "uri":"{{.context.argocdUrl}}/applications/{{.app.metadata.name}}"
              }]
            },
            {
              "@type":"OpenUri",
              "name":"Open Repository",
              "targets":[{
                "os":"default",
                "uri":"{{.app.spec.source.repoURL | call .repo.RepoURLToHTTPS}}"
              }]
            }]
          themeColor: '#FF0000'
          title: Application {{.app.metadata.name}} has degraded.
      template.app-sync-failed: |
        email:
          subject: Failed to sync application {{.app.metadata.name}}.
        message: |
          {{if eq .serviceType "slack"}}:exclamation:{{end}}  The sync operation of application {{.app.metadata.name}} has failed at {{.app.status.operationState.finishedAt}} with the following error: {{.app.status.operationState.message}}
          Sync operation details are available at: {{.context.argocdUrl}}/applications/{{.app.metadata.name}}?operation=true .
        slack:
          attachments: |
            [{
              "title": "{{ .app.metadata.name}}",
              "title_link":"{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
              "color": "#E96D76",
              "fields": [
              {
                "title": "Sync Status",
                "value": "{{.app.status.sync.status}}",
                "short": true
              },
              {
                "title": "Repository",
                "value": "{{.app.spec.source.repoURL}}",
                "short": true
              }
              {{range $index, $c := .app.status.conditions}}
              ,
              {
                "title": "{{$c.type}}",
                "value": "{{$c.message}}",
                "short": true
              }
              {{end}}
              ]
            }]
          deliveryPolicy: Post
          groupingKey: ""
          notifyBroadcast: false
        teams:
          facts: |
            [{
              "name": "Sync Status",
              "value": "{{.app.status.sync.status}}"
            },
            {
              "name": "Failed at",
              "value": "{{.app.status.operationState.finishedAt}}"
            },
            {
              "name": "Repository",
              "value": "{{.app.spec.source.repoURL}}"
            }
            {{range $index, $c := .app.status.conditions}}
              ,
              {
                "name": "{{$c.type}}",
                "value": "{{$c.message}}"
              }
            {{end}}
            ]
          potentialAction: |-
            [{
              "@type":"OpenUri",
              "name":"Open Operation",
              "targets":[{
                "os":"default",
                "uri":"{{.context.argocdUrl}}/applications/{{.app.metadata.name}}?operation=true"
              }]
            },
            {
              "@type":"OpenUri",
              "name":"Open Repository",
              "targets":[{
                "os":"default",
                "uri":"{{.app.spec.source.repoURL | call .repo.RepoURLToHTTPS}}"
              }]
            }]
          themeColor: '#FF0000'
          title: Failed to sync application {{.app.metadata.name}}.
      template.app-sync-running: |
        email:
          subject: Start syncing application {{.app.metadata.name}}.
        message: |
          The sync operation of application {{.app.metadata.name}} has started at {{.app.status.operationState.startedAt}}.
          Sync operation details are available at: {{.context.argocdUrl}}/applications/{{.app.metadata.name}}?operation=true .
        slack:
          attachments: |
            [{
              "title": "{{ .app.metadata.name}}",
              "title_link":"{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
              "color": "#0DADEA",
              "fields": [
              {
                "title": "Sync Status",
                "value": "{{.app.status.sync.status}}",
                "short": true
              },
              {
                "title": "Repository",
                "value": "{{.app.spec.source.repoURL}}",
                "short": true
              }
              {{range $index, $c := .app.status.conditions}}
              ,
              {
                "title": "{{$c.type}}",
                "value": "{{$c.message}}",
                "short": true
              }
              {{end}}
              ]
            }]
          deliveryPolicy: Post
          groupingKey: ""
          notifyBroadcast: false
        teams:
          facts: |
            [{
              "name": "Sync Status",
              "value": "{{.app.status.sync.status}}"
            },
            {
              "name": "Started at",
              "value": "{{.app.status.operationState.startedAt}}"
            },
            {
              "name": "Repository",
              "value": "{{.app.spec.source.repoURL}}"
            }
            {{range $index, $c := .app.status.conditions}}
              ,
              {
                "name": "{{$c.type}}",
                "value": "{{$c.message}}"
              }
            {{end}}
            ]
          potentialAction: |-
            [{
              "@type":"OpenUri",
              "name":"Open Operation",
              "targets":[{
                "os":"default",
                "uri":"{{.context.argocdUrl}}/applications/{{.app.metadata.name}}?operation=true"
              }]
            },
            {
              "@type":"OpenUri",
              "name":"Open Repository",
              "targets":[{
                "os":"default",
                "uri":"{{.app.spec.source.repoURL | call .repo.RepoURLToHTTPS}}"
              }]
            }]
          title: Start syncing application {{.app.metadata.name}}.
      template.app-sync-status-unknown: |
        email:
          subject: Application {{.app.metadata.name}} sync status is 'Unknown'
        message: |
          {{if eq .serviceType "slack"}}:exclamation:{{end}} Application {{.app.metadata.name}} sync is 'Unknown'.
          Application details: {{.context.argocdUrl}}/applications/{{.app.metadata.name}}.
          {{if ne .serviceType "slack"}}
          {{range $c := .app.status.conditions}}
              * {{$c.message}}
          {{end}}
          {{end}}
        slack:
          attachments: |
            [{
              "title": "{{ .app.metadata.name}}",
              "title_link":"{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
              "color": "#E96D76",
              "fields": [
              {
                "title": "Sync Status",
                "value": "{{.app.status.sync.status}}",
                "short": true
              },
              {
                "title": "Repository",
                "value": "{{.app.spec.source.repoURL}}",
                "short": true
              }
              {{range $index, $c := .app.status.conditions}}
              ,
              {
                "title": "{{$c.type}}",
                "value": "{{$c.message}}",
                "short": true
              }
              {{end}}
              ]
            }]
          deliveryPolicy: Post
          groupingKey: ""
          notifyBroadcast: false
        teams:
          facts: |
            [{
              "name": "Sync Status",
              "value": "{{.app.status.sync.status}}"
            },
            {
              "name": "Repository",
              "value": "{{.app.spec.source.repoURL}}"
            }
            {{range $index, $c := .app.status.conditions}}
              ,
              {
                "name": "{{$c.type}}",
                "value": "{{$c.message}}"
              }
            {{end}}
            ]
          potentialAction: |-
            [{
              "@type":"OpenUri",
              "name":"Open Application",
              "targets":[{
                "os":"default",
                "uri":"{{.context.argocdUrl}}/applications/{{.app.metadata.name}}"
              }]
            },
            {
              "@type":"OpenUri",
              "name":"Open Repository",
              "targets":[{
                "os":"default",
                "uri":"{{.app.spec.source.repoURL | call .repo.RepoURLToHTTPS}}"
              }]
            }]
          title: Application {{.app.metadata.name}} sync status is 'Unknown'
      template.app-sync-succeeded: |
        email:
          subject: Application {{.app.metadata.name}} has been successfully synced.
        message: |
          {{if eq .serviceType "slack"}}:white_check_mark:{{end}} Application {{.app.metadata.name}} has been successfully synced at {{.app.status.operationState.finishedAt}}.
          Sync operation details are available at: {{.context.argocdUrl}}/applications/{{.app.metadata.name}}?operation=true .
        slack:
          attachments: |
            [{
              "title": "{{ .app.metadata.name}}",
              "title_link":"{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
              "color": "#18be52",
              "fields": [
              {
                "title": "Sync Status",
                "value": "{{.app.status.sync.status}}",
                "short": true
              },
              {
                "title": "Repository",
                "value": "{{.app.spec.source.repoURL}}",
                "short": true
              }
              {{range $index, $c := .app.status.conditions}}
              ,
              {
                "title": "{{$c.type}}",
                "value": "{{$c.message}}",
                "short": true
              }
              {{end}}
              ]
            }]
          deliveryPolicy: Post
          groupingKey: ""
          notifyBroadcast: false
        teams:
          facts: |
            [{
              "name": "Sync Status",
              "value": "{{.app.status.sync.status}}"
            },
            {
              "name": "Synced at",
              "value": "{{.app.status.operationState.finishedAt}}"
            },
            {
              "name": "Repository",
              "value": "{{.app.spec.source.repoURL}}"
            }
            {{range $index, $c := .app.status.conditions}}
              ,
              {
                "name": "{{$c.type}}",
                "value": "{{$c.message}}"
              }
            {{end}}
            ]
          potentialAction: |-
            [{
              "@type":"OpenUri",
              "name":"Operation Details",
              "targets":[{
                "os":"default",
                "uri":"{{.context.argocdUrl}}/applications/{{.app.metadata.name}}?operation=true"
              }]
            },
            {
              "@type":"OpenUri",
              "name":"Open Repository",
              "targets":[{
                "os":"default",
                "uri":"{{.app.spec.source.repoURL | call .repo.RepoURLToHTTPS}}"
              }]
            }]
          themeColor: '#000080'
          title: Application {{.app.metadata.name}} has been successfully synced
    triggers:
      trigger.on-created: |
        - description: Application is created.
          oncePer: app.metadata.name
          send:
          - app-created
          when: "true"
      trigger.on-deleted: |
        - description: Application is deleted.
          oncePer: app.metadata.name
          send:
          - app-deleted
          when: app.metadata.deletionTimestamp != nil
      trigger.on-deployed: |
        - description: Application is synced and healthy. Triggered once per commit.
          oncePer: app.status.operationState?.syncResult?.revision
          send:
          - app-deployed
          when: app.status.operationState != nil and app.status.operationState.phase in ['Succeeded']
            and app.status.health.status == 'Healthy'
      trigger.on-health-degraded: |
        - description: Application has degraded
          send:
          - app-health-degraded
          when: app.status.health.status == 'Degraded'
      trigger.on-sync-failed: |
        - description: Application syncing has failed
          send:
          - app-sync-failed
          when: app.status.operationState != nil and app.status.operationState.phase in ['Error',
            'Failed']
      trigger.on-sync-running: |
        - description: Application is being synced
          send:
          - app-sync-running
          when: app.status.operationState != nil and app.status.operationState.phase in ['Running']
      trigger.on-sync-status-unknown: |
        - description: Application status is 'Unknown'
          send:
          - app-sync-status-unknown
          when: app.status.sync.status == 'Unknown'
      trigger.on-sync-succeeded: |
        - description: Application syncing has succeeded
          send:
          - app-sync-succeeded
          when: app.status.operationState != nil and app.status.operationState.phase in ['Succeeded']
  EOF
}
