provider "vault" {
    address = var.vault_url
    token   = var.vault_token
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "cluster" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = "https://10.43.0.1:443"
  disable_iss_validation = true
}

resource "vault_mount" "projects" {
    path        = "projects"
    type        = "kv"
    options     = { version = "2" }
    description = "projects"
}

resource "vault_policy" "projects" {
    name = "projects"
    policy = <<EOT
path "projects/data/*" {
    capabilities = ["read"]
}
        EOT
    depends_on = [vault_mount.projects]
}


resource "vault_kubernetes_auth_backend_role" "projects" {
    backend                          = "kubernetes"
    role_name                        = "projects"
    bound_service_account_names      = ["*"]
    bound_service_account_namespaces = ["*"]
    token_ttl                        = 0
    token_policies                   = ["projects"]
    depends_on = [vault_mount.projects]
}

resource "vault_kv_secret_v2" "tgupload" {
        mount                      = vault_mount.projects.path
        name                       = "tgupload"
        cas                        = 1
        delete_all_versions        = true
        data_json                  = jsonencode(
        {
            TOKEN  = ""
        }
        )
    depends_on = [vault_mount.projects]
    lifecycle {
        ignore_changes = [
            data_json,
        ]
    }
}

