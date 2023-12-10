include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${dirname(find_in_parent_folders())}/_common/argocd/application_set.hcl"
}

inputs = {
  dest_cluster_list = [
    {
      cluster = "prod-0"
      domen = "from-the-lamp.com"
    }
  ]
  apps = [
    {
      helm_repo_url = "https://helm.runix.net"
      helm_chart_version = "1.18.5"
      values = <<EOT
      env:
        email: admin@admin.com
        password: ${uuid()}
      extraConfigmapMounts:
      - name: config-local
        configMap: pgadmin4-config
        subPath: config_local.py
        mountPath: "/pgadmin4/config_local.py"
        readOnly: true
      envVarsFromSecrets:
      - pgadmin4-config
      extraSecretMounts:
      - name: pgpass
        secret: pgadmin4-config
        mountPath: /pgpass
        subPath: pgpassfile
      extraInitContainers: |
        - name: prepare-pgpass
          image: docker.io/dpage/pgadmin4:6.2
          command: 
          - sh
          - -c
          - |
            export PASS_DIR=/var/lib/pgadmin &&\
            mkdir -p $PASS_DIR &&\ 
            cp /pgpass $PASS_DIR/pgpass &&\
            chown -R pgadmin:pgadmin /var/lib/pgadmin &&\
            chmod 600 $PASS_DIR/pgpass
          volumeMounts:
          - name: pgadmin-data
            mountPath: /var/lib/pgadmin
          - name: pgpass
            subPath: pgpassfile
            mountPath: /pgpass
          securityContext:
            runAsUser: 0
      serverDefinitions:
        enabled: true
        servers:
          firstServer:
            Name: "postgresql-hl"
            Group: "Servers"
            Port: 5432
            Username: "postgres"
            Host: "postgresql-hl"
            SSLMode: "prefer"
            PassFile: "../../pgpass"
            Shared: true
            SharedUsername: "postgres"
            MaintenanceDB: "postgres"
      EOT
    },
    {
      app_name = "pgadmin4-gateway"
      helm_chart_name = "istio-gateway"
      helm_chart_version = "0.0.7"
      values = <<EOT
      hosts:
      - pgadmin.from-the-lamp.com
      external: true
      virtualService:
        destination:
          host: pgadmin4
          port: 80
      EOT
    }
  ]
}
