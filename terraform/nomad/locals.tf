locals {
  repository_root = abspath("${path.root}/../..")
  jobspec_path    = "${local.repository_root}/nomad/crowler.nomad.hcl"
  config_path     = "${local.repository_root}/config.yaml"

  user_agents  = sort(tolist(fileset("${local.repository_root}/user/agents", "*.{yaml,yml,json}")))
  user_plugins = sort(tolist(fileset("${local.repository_root}/user/plugins", "*.js")))
  user_rules   = sort(tolist(fileset("${local.repository_root}/user/rules", "*.{yaml,yml,json}")))
  user_support = sort([
    for filename in fileset("${local.repository_root}/user/support", "*") : filename
    if !startswith(filename, ".")
  ])

  deployment_file_hashes = concat(
    [filesha256(local.config_path)],
    [for filename in local.user_agents : filesha256("${local.repository_root}/user/agents/${filename}")],
    [for filename in local.user_plugins : filesha256("${local.repository_root}/user/plugins/${filename}")],
    [for filename in local.user_rules : filesha256("${local.repository_root}/user/rules/${filename}")],
    [for filename in local.user_support : filesha256("${local.repository_root}/user/support/${filename}")],
  )

  deployment_content_digest = sha256(join(":", local.deployment_file_hashes))

  raw_jobspec = file(local.jobspec_path)

  # The direct Nomad workflow intentionally uses repository-root-relative
  # file()/fileset() paths. Terraform runs with -chdir, so adapt the submitted
  # jobspec in memory to absolute paths rather than changing the Nomad source
  # of truth.
  jobspec_01 = replace(
    local.raw_jobspec,
    "fileset(\"./user/agents\", \"*.{yaml,yml,json}\")",
    "fileset(\"${local.repository_root}/user/agents\", \"*.{yaml,yml,json}\")",
  )

  jobspec_02 = replace(
    local.jobspec_01,
    "fileset(\"./user/plugins\", \"*.js\")",
    "fileset(\"${local.repository_root}/user/plugins\", \"*.js\")",
  )

  jobspec_03 = replace(
    local.jobspec_02,
    "fileset(\"./user/rules\", \"*.{yaml,yml,json}\")",
    "fileset(\"${local.repository_root}/user/rules\", \"*.{yaml,yml,json}\")",
  )

  jobspec_04 = replace(
    local.jobspec_03,
    "fileset(\"./user/support\", \"*\")",
    "fileset(\"${local.repository_root}/user/support\", \"*\")",
  )

  jobspec_05 = replace(
    local.jobspec_04,
    "file(\"./config.yaml\")",
    "file(\"${local.repository_root}/config.yaml\")",
  )

  jobspec_06 = replace(
    local.jobspec_05,
    "file(\"./user/agents/$${user_file.value}\")",
    "file(\"${local.repository_root}/user/agents/$${user_file.value}\")",
  )

  jobspec_07 = replace(
    local.jobspec_06,
    "file(\"./user/plugins/$${user_file.value}\")",
    "file(\"${local.repository_root}/user/plugins/$${user_file.value}\")",
  )

  jobspec_08 = replace(
    local.jobspec_07,
    "file(\"./user/rules/$${user_file.value}\")",
    "file(\"${local.repository_root}/user/rules/$${user_file.value}\")",
  )

  jobspec_09 = replace(
    local.jobspec_08,
    "file(\"./user/support/$${user_file.value}\")",
    "file(\"${local.repository_root}/user/support/$${user_file.value}\")",
  )

  # The Nomad provider cannot independently notice changes to files that are
  # only consumed by HCL filesystem functions. Add a harmless digest comment
  # so config/user-content changes become Terraform-visible jobspec changes.
  tracked_jobspec = "${local.jobspec_09}\n# terraform-deployment-content-digest=${local.deployment_content_digest}\n"

  # nomad_job.hcl2.vars requires string representations of HCL values.
  nomad_hcl_vars = {
    datacenters              = jsonencode(var.datacenters)
    namespace                = jsonencode(var.namespace)
    crowler_version          = jsonencode(var.crowler_version)
    vdi_version              = jsonencode(var.vdi_version)
    engine_count             = tostring(var.engine_count)
    vdi_count                = tostring(var.vdi_count)
    database_enabled         = tostring(var.database_enabled)
    api_enabled              = tostring(var.api_enabled)
    events_enabled           = tostring(var.events_enabled)
    jaeger_enabled           = tostring(var.jaeger_enabled)
    pushgateway_enabled      = tostring(var.pushgateway_enabled)
    external_db_host         = jsonencode(var.external_db_host)
    external_selenium_host   = jsonencode(var.external_selenium_host)
    external_prometheus_host = jsonencode(var.external_prometheus_host)
    database_volume_source   = jsonencode(var.database_volume_source)
    db_cpu                   = tostring(var.db_cpu)
    db_memory                = tostring(var.db_memory)
    api_cpu                  = tostring(var.api_cpu)
    api_memory               = tostring(var.api_memory)
    events_cpu               = tostring(var.events_cpu)
    events_memory            = tostring(var.events_memory)
    engine_cpu               = tostring(var.engine_cpu)
    engine_memory            = tostring(var.engine_memory)
    vdi_cpu                  = tostring(var.vdi_cpu)
    vdi_memory               = tostring(var.vdi_memory)
    jaeger_cpu               = tostring(var.jaeger_cpu)
    jaeger_memory            = tostring(var.jaeger_memory)
    pushgateway_cpu          = tostring(var.pushgateway_cpu)
    pushgateway_memory       = tostring(var.pushgateway_memory)
  }
}
