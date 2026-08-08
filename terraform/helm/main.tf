resource "kubernetes_namespace_v1" "crowler" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/part-of"    = "thecrowler"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_config_map_v1" "crowler_config" {
  metadata {
    name      = local.config_map_name
    namespace = var.namespace

    labels = {
      "app.kubernetes.io/part-of"    = "thecrowler"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  data = {
    "config.yaml" = file(local.config_path)
  }

  depends_on = [kubernetes_namespace_v1.crowler]
}

resource "kubernetes_secret_v1" "crowler" {
  metadata {
    name      = local.secret_name
    namespace = var.namespace

    labels = {
      "app.kubernetes.io/part-of"    = "thecrowler"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  type = "Opaque"

  # Kubernetes provider 3.x write-only attributes prevent the secret payload
  # from being persisted in Terraform state.
  data_wo          = local.secret_data
  data_wo_revision = var.kubernetes_secret_revision

  # terraform/run.sh validates the baseline required keys before Terraform
  # starts. Avoid re-reading sensitive write-only payload content in lifecycle
  # conditions.
  depends_on = [kubernetes_namespace_v1.crowler]
}

resource "kubernetes_config_map_v1" "user_agents" {
  metadata {
    name      = local.user_agents_config_map
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/part-of"    = "thecrowler"
      "app.kubernetes.io/managed-by" = "terraform"
      "thecrowler.io/content-type"   = "agents"
    }
  }

  data       = local.user_agents
  depends_on = [kubernetes_namespace_v1.crowler]
}

resource "kubernetes_config_map_v1" "user_plugins" {
  metadata {
    name      = local.user_plugins_config_map
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/part-of"    = "thecrowler"
      "app.kubernetes.io/managed-by" = "terraform"
      "thecrowler.io/content-type"   = "plugins"
    }
  }

  data       = local.user_plugins
  depends_on = [kubernetes_namespace_v1.crowler]
}

resource "kubernetes_config_map_v1" "user_rules" {
  metadata {
    name      = local.user_rules_config_map
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/part-of"    = "thecrowler"
      "app.kubernetes.io/managed-by" = "terraform"
      "thecrowler.io/content-type"   = "rules"
    }
  }

  data       = local.user_rules
  depends_on = [kubernetes_namespace_v1.crowler]
}

resource "kubernetes_config_map_v1" "user_support" {
  metadata {
    name      = local.user_support_config_map
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/part-of"    = "thecrowler"
      "app.kubernetes.io/managed-by" = "terraform"
      "thecrowler.io/content-type"   = "support"
    }
  }

  data       = local.user_support
  depends_on = [kubernetes_namespace_v1.crowler]
}

resource "helm_release" "crowler" {
  name      = var.release_name
  namespace = var.namespace
  chart     = local.chart_path

  atomic          = var.atomic
  cleanup_on_fail = true
  wait            = true
  wait_for_jobs   = true
  timeout         = var.timeout_seconds

  values = [
    yamlencode(local.helm_values),
  ]

  depends_on = [
    kubernetes_config_map_v1.crowler_config,
    kubernetes_secret_v1.crowler,
    kubernetes_config_map_v1.user_agents,
    kubernetes_config_map_v1.user_plugins,
    kubernetes_config_map_v1.user_rules,
    kubernetes_config_map_v1.user_support,
  ]

  lifecycle {
    precondition {
      condition     = var.database_enabled || trimspace(var.external_db_host) != ""
      error_message = "external_db_host is required when database_enabled=false."
    }
  }
}
