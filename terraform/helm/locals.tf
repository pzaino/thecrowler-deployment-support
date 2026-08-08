locals {
  repository_root = abspath("${path.root}/../..")
  chart_path       = "${local.repository_root}/helm/thecrowler"
  config_path      = "${local.repository_root}/config.yaml"

  config_map_name = "${var.release_name}-config"
  secret_name     = "${var.release_name}-secrets"

  user_agents_config_map  = "${var.release_name}-user-agents"
  user_plugins_config_map = "${var.release_name}-user-plugins"
  user_rules_config_map   = "${var.release_name}-user-rules"
  user_support_config_map = "${var.release_name}-user-support"

  user_agents_files = sort(tolist(fileset("${local.repository_root}/user/agents", "*.{yaml,yml,json}")))
  user_plugins_files = sort(tolist(fileset("${local.repository_root}/user/plugins", "*.js")))
  user_rules_files = sort(tolist(fileset("${local.repository_root}/user/rules", "*.{yaml,yml,json}")))
  user_support_files = sort([
    for filename in fileset("${local.repository_root}/user/support", "*") : filename
    if !startswith(filename, ".")
  ])

  user_agents = {
    for filename in local.user_agents_files :
    filename => file("${local.repository_root}/user/agents/${filename}")
  }

  user_plugins = {
    for filename in local.user_plugins_files :
    filename => file("${local.repository_root}/user/plugins/${filename}")
  }

  user_rules = {
    for filename in local.user_rules_files :
    filename => file("${local.repository_root}/user/rules/${filename}")
  }

  # ConfigMaps contain UTF-8 text. Large/binary support artifacts require a
  # PVC, object storage, or another artifact-distribution mechanism.
  user_support = {
    for filename in local.user_support_files :
    filename => file("${local.repository_root}/user/support/${filename}")
  }

  config_digest = filesha256(local.config_path)

  user_content_digest = sha256(jsonencode({
    agents  = local.user_agents
    plugins = local.user_plugins
    rules   = local.user_rules
    support = local.user_support
  }))

  secret_data = tomap(jsondecode(var.kubernetes_secret_json))

  helm_values = {
    global = {
      crowlerVersion = var.crowler_version
      vdiVersion     = var.vdi_version
    }

    config = {
      create            = false
      existingConfigMap = local.config_map_name
      rolloutToken      = local.config_digest
    }

    secrets = {
      create         = false
      existingSecret = local.secret_name
      rolloutToken   = tostring(var.kubernetes_secret_revision)
    }

    userContent = {
      enabled          = true
      agentsConfigMap  = local.user_agents_config_map
      pluginsConfigMap = local.user_plugins_config_map
      rulesConfigMap   = local.user_rules_config_map
      supportConfigMap = local.user_support_config_map
      rolloutToken     = local.user_content_digest
    }

    database = {
      enabled = var.database_enabled
      host    = var.external_db_host

      persistence = {
        enabled      = true
        size         = var.database_storage_size
        storageClass = var.database_storage_class
      }
    }

    api = {
      replicas = var.api_replicas
    }

    events = {
      replicas = var.events_replicas
    }

    engine = {
      replicas = var.engine_replicas
    }

    vdi = {
      replicas = var.vdi_replicas
    }

    jaeger = {
      enabled = var.jaeger_enabled
    }

    pushgateway = {
      enabled = var.pushgateway_enabled
    }
  }
}
