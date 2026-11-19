include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/_modules/oneuptime/project_settings"
  # source = "${local.modules_url}/${local.module_dir}?tag=${local.module_version}"
}

locals {
  common_settings = read_terragrunt_config("${get_repo_root()}/root.hcl")
  modules_url     = local.common_settings.locals.private_modules_base_url
  module_dir      = "oneuptime/project_settings"
  module_version  = "0.2.0"
}

include "oneuptime_provider" {
  path = "${get_repo_root()}/_common/oneuptime/provider.hcl"
}

inputs = {
  project_id = "20d35059-271e-4472-9849-d9ca99582870"
  name       = "from-the-lamp"

  enable_automatic_incident_investigation = true
  enable_automatic_alert_investigation    = true
  enable_automatic_postmortem_draft       = true

  enable_automatic_incident_remediation = true
  enable_automatic_alert_remediation    = true

  ai_daily_token_limit         = 40000000
  ai_run_time_limit_in_minutes = 30

  incident_ai_max_concurrent_investigations = 1
  alert_ai_max_concurrent_investigations    = 1

  incident_investigation_dedupe_window_minutes = 0
  alert_investigation_dedupe_window_minutes    = 0

  incident_ai_daily_fix_task_limit = 5
  alert_ai_daily_fix_task_limit    = 5

  ai_context = <<-EOT
    Все расследования, заметки, постмортемы и ответы пиши на русском языке.

    Платформа from-the-lamp управляется через GitOps. Кластер homelab
    (Talos, один узел homelab-node-1) синхронизируется Argo CD из
    репозиториев группы gitlab.com/from-the-lamp/infra:
    - argo-apps - что развёрнуто в кластере: apps/homelab/platform/<app>/
      с values.yaml и версиями чартов. Лимиты памяти и CPU, реплики,
      правила алертов и конфигурация приложений живут здесь.
    - helm-charts - исходники чартов lamp-<component>.
    - docker-images - исходники образов.
    - terraform/modules и terraform/terragrunt - инфраструктура.

    Правка values.yaml, манифеста или чарта в этих репозиториях - это и
    есть исправление в коде: оформляй её как merge request. Изменения
    через kubectl не подходят, Argo CD вернёт состояние из git.

    В самом OneUptime телеметрии нет: инциденты и алерты приходят
    вебхуком из Alertmanager, в описании есть namespace, pod и container.
    Доказательства бери через MCP-сервер "from-the-lamp platform tools
    (read-only)": метрики VictoriaMetrics и логи Loki через инструменты
    Grafana, состояние подов, события и логи контейнеров через
    инструменты Kubernetes, состояние приложений через Argo CD,
    содержимое репозиториев через GitLab. Перед выводом о причине проверь
    фактическое потребление ресурсов и логи, а не только текст алерта.

    Алерт KubeContainerOOMKilled означает, что контейнеру не хватило
    лимита памяти: исправление - поднять resources.limits.memory этого
    приложения в argo-apps.

    Никогда не мерджи merge request сам: его смотрит и мерджит человек.
    Не запускай terraform или terragrunt plan и apply. Если причина не в
    репозиториях платформы или ты не уверен в конкретной правке - не
    открывай merge request, опиши причину и что нужен ручной разбор.
  EOT
}
