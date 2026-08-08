output "job_name" {
  value = nomad_job.crowler.name
}

output "job_namespace" {
  value = nomad_job.crowler.namespace
}

output "deployment_content_digest" {
  value = local.deployment_content_digest
}

output "database_volume_name" {
  value = var.database_enabled ? var.database_volume_source : null
}

output "nomad_variable_path" {
  value = nomad_variable.crowler_env.path
}
