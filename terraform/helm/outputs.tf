output "release_name" {
  value = helm_release.crowler.name
}

output "namespace" {
  value = var.namespace
}

output "config_map_name" {
  value = kubernetes_config_map_v1.crowler_config.metadata[0].name
}

output "secret_name" {
  value = kubernetes_secret_v1.crowler.metadata[0].name
}

output "user_content_config_maps" {
  value = {
    agents  = kubernetes_config_map_v1.user_agents.metadata[0].name
    plugins = kubernetes_config_map_v1.user_plugins.metadata[0].name
    rules   = kubernetes_config_map_v1.user_rules.metadata[0].name
    support = kubernetes_config_map_v1.user_support.metadata[0].name
  }
}

output "config_digest" {
  value = local.config_digest
}

output "user_content_digest" {
  value = local.user_content_digest
}
