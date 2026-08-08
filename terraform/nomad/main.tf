resource "nomad_variable" "crowler_env" {
  path      = "nomad/jobs/crowler/env"
  namespace = var.namespace

  # Nomad provider 2.6 write-only attribute. Sensitive payload values are sent
  # to Nomad without being persisted in Terraform state.
  items_wo         = var.nomad_env_json
  items_wo_version = var.nomad_env_revision
}

resource "nomad_dynamic_host_volume" "database" {
  count = var.database_enabled && var.manage_database_volume ? 1 : 0

  name      = var.database_volume_source
  namespace = var.namespace
  plugin_id = "mkdir"

  capacity_min = var.database_volume_capacity
  capacity_max = var.database_volume_capacity

  capability {
    access_mode     = "single-node-single-writer"
    attachment_mode = "file-system"
  }

  constraint {
    attribute = "$${attr.kernel.name}"
    value     = "linux"
  }

  parameters = {
    mode = var.database_volume_mode
  }

  lifecycle {
    # HashiCorp explicitly warns that deleting a dynamic host volume can cause
    # data loss. Database storage must require an intentional migration or
    # destruction procedure.
    prevent_destroy = true
  }
}

resource "nomad_job" "crowler" {
  jobspec = local.tracked_jobspec
  detach  = var.detach

  deregister_on_destroy   = true
  purge_on_destroy        = false
  deregister_on_id_change = true

  hcl2 {
    allow_fs = true
    vars     = local.nomad_hcl_vars
  }

  depends_on = [
    nomad_variable.crowler_env,
    nomad_dynamic_host_volume.database,
  ]

  lifecycle {
    precondition {
      condition     = strcontains(local.raw_jobspec, "file(\"./config.yaml\")")
      error_message = "nomad/crowler.nomad.hcl no longer matches the expected repository-root filesystem contract. Review terraform/nomad/locals.tf before applying."
    }

    precondition {
      condition     = var.database_enabled || trimspace(var.external_db_host) != ""
      error_message = "external_db_host is required when database_enabled=false."
    }

    precondition {
      condition     = var.vdi_count > 0 || trimspace(var.external_selenium_host) != ""
      error_message = "external_selenium_host is required when vdi_count=0."
    }
  }

  timeouts {
    create = "10m"
    update = "10m"
  }
}
