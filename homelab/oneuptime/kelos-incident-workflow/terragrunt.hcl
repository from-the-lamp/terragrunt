include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${local.modules_url}/${local.module_dir}?tag=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/root.hcl")
  modules_url     = local.common_settings.locals.private_modules_base_url
  module_dir      = "oneuptime/workflow"
  module_version  = "0.1.0"

  trigger_id = "incident-on-create-1"
  post_id    = "api-post-1"
  incident   = "local.components.${local.trigger_id}.returnValues.model"
}

include "oneuptime_provider" {
  path = "${get_repo_root()}/_common/oneuptime/provider.hcl"
}

inputs = {
  name        = "Incident to Kelos"
  is_enabled  = false
  description = "Posts every new incident to the Kelos generic webhook; the Kelos TaskSpawner decides which severities start an agent."

  graph = {
    nodes = [
      {
        id       = local.trigger_id
        position = { x = 0, y = 0 }
        data = {
          id            = local.trigger_id
          internalId    = local.trigger_id
          metadataId    = "incident-on-create"
          nodeType      = "Node"
          componentType = "Trigger"
          error         = ""
          arguments = {
            select = {
              _id              = true
              projectId        = true
              incidentNumber   = true
              title            = true
              incidentSeverity = { name = true }
            }
          }
          returnValues = {}
        }
      },
      {
        id       = local.post_id
        position = { x = 300, y = 0 }
        data = {
          id            = local.post_id
          internalId    = local.post_id
          metadataId    = "api-post"
          nodeType      = "Node"
          componentType = "Component"
          error         = ""
          arguments = {
            url = "http://kelos-webhook-generic.kelos.svc.cluster.local:8443/webhook/oneuptime"
            "request-body" = jsonencode({
              incidentId     = "{{${local.incident}._id}}"
              incidentNumber = "{{${local.incident}.incidentNumber}}"
              projectId      = "{{${local.incident}.projectId.value}}"
              title          = "{{${local.incident}.title}}"
              severity       = "{{${local.incident}.incidentSeverity.name}}"
            })
          }
          returnValues = {}
        }
      },
    ]
    edges = [
      {
        id           = "${local.trigger_id}-success-to-${local.post_id}-in"
        source       = local.trigger_id
        target       = local.post_id
        sourceHandle = "success"
        targetHandle = "in"
      },
    ]
  }
}
