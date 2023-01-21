# include "root" {
#   path = find_in_parent_folders()
# }

# include "common" {
#   path = "${dirname(find_in_parent_folders())}/_common/helm.hcl"
# }

# inputs = {
#   helm_external_repo    = true
#   helm_values_file      = "values.yml"
#   helm_repo_url         = "https://charts.releases.teleport.dev"
#   helm_chart_name       = "teleport-cluster"
#   helm_chart_version    = "11.2.2"
#   helm_virtual_service  = true
#   helm_addition_setting = {
#     "gateway.port" = "443"
#   }
# }
