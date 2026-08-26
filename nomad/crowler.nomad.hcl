# The CROWler - HashiCorp Nomad deployment
#
# IMPORTANT:
# Run Nomad CLI commands from the repository root.
# HCL file() and fileset() calls below intentionally resolve:
#
#   ./config.yaml
#   ./user/agents
#   ./user/plugins
#   ./user/rules
#   ./user/support
#
# from the operator's current working directory.

variable "datacenters" {
  type    = list(string)
  default = ["dc1"]
}

variable "namespace" {
  type    = string
  default = "default"
}

variable "crowler_version" {
  type    = string
  default = "2.1.0"
}

variable "vdi_version" {
  type    = string
  default = "4.28.1-20260819"
}

variable "engine_count" {
  type    = number
  default = 2
}

variable "vdi_count" {
  type    = number
  default = 2
}

variable "database_enabled" {
  type    = bool
  default = true
}

variable "api_enabled" {
  type    = bool
  default = true
}

variable "events_enabled" {
  type    = bool
  default = true
}

variable "jaeger_enabled" {
  type    = bool
  default = true
}

variable "pushgateway_enabled" {
  type    = bool
  default = false
}

variable "external_db_host" {
  type    = string
  default = ""
}

variable "external_selenium_host" {
  type    = string
  default = ""
}

variable "external_prometheus_host" {
  type    = string
  default = ""
}

variable "database_volume_source" {
  type    = string
  default = "crowler-db-data"
}

variable "db_cpu" {
  type    = number
  default = 1000
}

variable "db_memory" {
  type    = number
  default = 2048
}

variable "api_cpu" {
  type    = number
  default = 500
}

variable "api_memory" {
  type    = number
  default = 1024
}

variable "events_cpu" {
  type    = number
  default = 500
}

variable "events_memory" {
  type    = number
  default = 1024
}

variable "engine_cpu" {
  type    = number
  default = 1000
}

variable "engine_memory" {
  type    = number
  default = 2048
}

variable "vdi_cpu" {
  type    = number
  default = 2000
}

variable "vdi_memory" {
  type    = number
  default = 4096
}

variable "jaeger_cpu" {
  type    = number
  default = 500
}

variable "jaeger_memory" {
  type    = number
  default = 1024
}

variable "pushgateway_cpu" {
  type    = number
  default = 250
}

variable "pushgateway_memory" {
  type    = number
  default = 512
}

locals {
  # These functions run in the local Nomad CLI parsing context.
  user_agents  = tolist(fileset("./user/agents", "*.{yaml,yml,json}"))
  user_plugins = tolist(fileset("./user/plugins", "*.js"))
  user_rules   = tolist(fileset("./user/rules", "*.{yaml,yml,json}"))
  user_support = [
    for filename in fileset("./user/support", "*") : filename
    if !startswith(filename, ".")
  ]

  # Environment imported by nomad/bootstrap-env.sh is encrypted in a Nomad
  # Variable at this job-owned path.
  common_env_template = <<-EOT
{{ if nomadVarExists "nomad/jobs/crowler/env" -}}
{{ with nomadVar "nomad/jobs/crowler/env" -}}
{{ range .Tuples -}}
{{ .K }}={{ .V.Value | toJSON }}
{{ end -}}
{{ end -}}
{{ end -}}
EOT

  crowler_db_credentials_template = <<-EOT
{{ if nomadVarExists "nomad/jobs/crowler/env" -}}
{{ with nomadVar "nomad/jobs/crowler/env" -}}
CROWLER_DB_USER={{ .DOCKER_CROWLER_DB_USER.Value | toJSON }}
CROWLER_DB_PASSWORD={{ .DOCKER_CROWLER_DB_PASSWORD.Value | toJSON }}
{{ end -}}
{{ end -}}
EOT

  database_credentials_template = <<-EOT
{{ if nomadVarExists "nomad/jobs/crowler/env" -}}
{{ with nomadVar "nomad/jobs/crowler/env" -}}
POSTGRES_PASSWORD={{ .DOCKER_POSTGRES_PASSWORD.Value | toJSON }}
CROWLER_DB_USER={{ .DOCKER_CROWLER_DB_USER.Value | toJSON }}
CROWLER_DB_PASSWORD={{ .DOCKER_CROWLER_DB_PASSWORD.Value | toJSON }}
{{ end -}}
{{ end -}}
EOT

  database_host_template = <<-EOT
%{ if var.database_enabled ~}
{{$allocID := env "NOMAD_ALLOC_ID" -}}
{{ range nomadService 1 $allocID "crowler-db" -}}
DOCKER_DB_HOST={{ .Address | toJSON }}
{{ end -}}
%{ else ~}
DOCKER_DB_HOST=${jsonencode(var.external_db_host)}
%{ endif ~}
EOT

  selenium_host_template = <<-EOT
%{ if var.vdi_count > 0 ~}
{{$allocID := env "NOMAD_ALLOC_ID" -}}
{{ range nomadService 1 $allocID "crowler-vdi" -}}
SELENIUM_HOST={{ .Address | toJSON }}
{{ end -}}
%{ else ~}
SELENIUM_HOST=${jsonencode(var.external_selenium_host)}
%{ endif ~}
EOT

  prometheus_host_template = <<-EOT
%{ if var.pushgateway_enabled ~}
{{$allocID := env "NOMAD_ALLOC_ID" -}}
{{ range nomadService 1 $allocID "crowler-push-gateway" -}}
PROMETHEUS_HOST={{ .Address | toJSON }}
{{ end -}}
%{ else ~}
PROMETHEUS_HOST=${jsonencode(var.external_prometheus_host)}
%{ endif ~}
EOT

  jaeger_env_template = <<-EOT
%{ if var.jaeger_enabled ~}
SE_ENABLE_TRACING="true"
{{$allocID := env "NOMAD_ALLOC_ID" -}}
{{ range nomadService 1 $allocID "crowler-jaeger-otlp" -}}
SE_OTEL_EXPORTER_ENDPOINT={{ printf "http://%s:%d" .Address .Port | toJSON }}
{{ end -}}
%{ else ~}
SE_ENABLE_TRACING="false"
SE_OTEL_EXPORTER_ENDPOINT=""
%{ endif ~}
EOT
}

job "crowler" {
  datacenters = var.datacenters
  namespace   = var.namespace
  type        = "service"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  update {
    max_parallel      = 1
    min_healthy_time  = "10s"
    healthy_deadline  = "5m"
    progress_deadline = "10m"
    auto_revert       = true
    auto_promote      = true
  }

  # ---------------------------------------------------------------------------
  # PostgreSQL
  # ---------------------------------------------------------------------------
  group "database" {
    count = var.database_enabled ? 1 : 0

    network {
      mode = "bridge"

      port "db" {
        static = 5432
        to     = 5432
      }
    }

    dynamic "volume" {
      for_each = var.database_enabled ? toset(["db-data"]) : toset([])
      labels   = [volume.value]

      content {
        type            = "host"
        source          = var.database_volume_source
        read_only       = false
        sticky          = true
        access_mode     = "single-node-single-writer"
        attachment_mode = "file-system"
      }
    }

    service {
      name         = "crowler-db"
      provider     = "nomad"
      port         = "db"
      address_mode = "host"

      check {
        name     = "postgres-tcp"
        type     = "tcp"
        port     = "db"
        interval = "10s"
        timeout  = "3s"
      }
    }

    restart {
      attempts = 10
      interval = "10m"
      delay    = "10s"
      mode     = "delay"
    }

    task "crowler-db" {
      driver = "docker"

      config {
        image = "zfpsystems/crowler-db:${var.crowler_version}"
        ports = ["db"]
      }

      env {
        POSTGRES_DB       = "SitesIndex"
        POSTGRES_USER     = "postgres"
        TZ                = "UTC"
        MICROSERVICE_NAME = "crowler-db"
      }

      template {
        data        = local.common_env_template
        destination = "secrets/crowler-root.env"
        env         = true
        change_mode = "restart"
      }

      template {
        data        = local.database_credentials_template
        destination = "secrets/crowler-db.env"
        env         = true
        change_mode = "restart"
      }

      dynamic "volume_mount" {
        for_each = var.database_enabled ? toset(["db-data"]) : toset([])
        iterator = db_volume

        content {
          volume      = db_volume.value
          destination = "/var/lib/postgresql/data"
          read_only   = false
        }
      }

      resources {
        cpu    = var.db_cpu
        memory = var.db_memory
      }
    }
  }

  # ---------------------------------------------------------------------------
  # VDI pool
  # ---------------------------------------------------------------------------
  group "vdi" {
    count = var.vdi_count

    constraint {
      distinct_hosts = true
    }

    network {
      mode = "bridge"

      port "selenium" {
        static = 4444
        to     = 4444
      }

      port "management" {
        static = 4445
        to     = 4445
      }

      port "vnc" {
        static = 5900
        to     = 5900
      }

      port "novnc" {
        static = 7900
        to     = 7900
      }

      port "cdp" {
        static = 9222
        to     = 9222
      }
    }

    service {
      name         = "crowler-vdi"
      provider     = "nomad"
      port         = "selenium"
      address_mode = "host"

      check {
        name     = "selenium-tcp"
        type     = "tcp"
        port     = "selenium"
        interval = "10s"
        timeout  = "3s"
      }
    }

    restart {
      attempts = 10
      interval = "10m"
      delay    = "10s"
      mode     = "delay"
    }

    task "crowler-vdi" {
      driver = "docker"

      config {
        image    = "zfpsystems/crowler-vdi:${var.vdi_version}"
        ports    = ["selenium", "management", "vnc", "novnc", "cdp"]
        shm_size = 2147483648
      }

      env {
        INSTANCE_ID                = "${NOMAD_ALLOC_INDEX}"
        SE_SCREEN_WIDTH            = "1920"
        SE_SCREEN_HEIGHT           = "1080"
        SE_SCREEN_DEPTH            = "24"
        SE_ROLE                    = "standalone"
        SE_REJECT_UNSUPPORTED_CAPS = "true"
        SE_NODE_ENABLE_CDP         = "true"
        SE_OTEL_TRACES_EXPORTER    = "otlp"
        TZ                         = "UTC"
        MICROSERVICE_NAME          = "crowler-vdi-${NOMAD_ALLOC_INDEX}"
      }

      template {
        data        = local.common_env_template
        destination = "secrets/crowler-root.env"
        env         = true
        change_mode = "restart"
      }

      template {
        data        = local.jaeger_env_template
        destination = "local/jaeger.env"
        env         = true
        change_mode = "restart"
      }

      resources {
        cpu    = var.vdi_cpu
        memory = var.vdi_memory
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Jaeger
  # ---------------------------------------------------------------------------
  group "jaeger" {
    count = var.jaeger_enabled ? 1 : 0

    network {
      mode = "bridge"

      port "ui" {
        static = 16686
        to     = 16686
      }

      port "otlp" {
        to = 4317
      }
    }

    service {
      name         = "crowler-jaeger-otlp"
      provider     = "nomad"
      port         = "otlp"
      address_mode = "host"

      check {
        name     = "jaeger-otlp-tcp"
        type     = "tcp"
        port     = "otlp"
        interval = "10s"
        timeout  = "3s"
      }
    }

    service {
      name         = "crowler-jaeger-ui"
      provider     = "nomad"
      port         = "ui"
      address_mode = "host"
    }

    task "crowler-jaeger" {
      driver = "docker"

      config {
        image = "jaegertracing/all-in-one:1.54"
        ports = ["ui", "otlp"]
      }

      env {
        COLLECTOR_ZIPKIN_HTTP_PORT = "9411"
        JAEGER_SERVICE_NAME        = "crowler-jaeger"
        TZ                         = "UTC"
        MICROSERVICE_NAME          = "crowler-jaeger"
      }

      resources {
        cpu    = var.jaeger_cpu
        memory = var.jaeger_memory
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Prometheus Pushgateway
  # ---------------------------------------------------------------------------
  group "pushgateway" {
    count = var.pushgateway_enabled ? 1 : 0

    network {
      mode = "bridge"

      port "http" {
        static = 9091
        to     = 9091
      }
    }

    service {
      name         = "crowler-push-gateway"
      provider     = "nomad"
      port         = "http"
      address_mode = "host"

      check {
        name     = "pushgateway-http"
        type     = "http"
        path     = "/-/ready"
        port     = "http"
        interval = "10s"
        timeout  = "3s"
      }
    }

    task "crowler-push-gateway" {
      driver = "docker"

      config {
        image = "prom/pushgateway:latest"
        ports = ["http"]
      }

      env {
        MICROSERVICE_NAME = "crowler-push-gateway"
      }

      resources {
        cpu    = var.pushgateway_cpu
        memory = var.pushgateway_memory
      }
    }
  }

  # ---------------------------------------------------------------------------
  # API
  # ---------------------------------------------------------------------------
  group "api" {
    count = var.api_enabled ? 1 : 0

    network {
      mode = "bridge"

      port "http" {
        static = 8080
        to     = 8080
      }
    }

    service {
      name         = "crowler-api"
      provider     = "nomad"
      port         = "http"
      address_mode = "host"

      check {
        name     = "api-tcp"
        type     = "tcp"
        port     = "http"
        interval = "10s"
        timeout  = "3s"
      }
    }

    restart {
      attempts = 10
      interval = "10m"
      delay    = "10s"
      mode     = "delay"
    }

    task "crowler-api" {
      driver = "docker"

      config {
        image           = "zfpsystems/crowler-api:${var.crowler_version}"
        ports           = ["http"]
        readonly_rootfs = true

        mount {
          type     = "bind"
          source   = "local/config.yaml"
          target   = "/app/config.yaml"
          readonly = true
        }

        mount {
          type     = "bind"
          source   = "local/user/agents"
          target   = "/app/user/agents"
          readonly = true
        }

        mount {
          type     = "bind"
          source   = "local/user/plugins"
          target   = "/app/user/plugins"
          readonly = true
        }

        mount {
          type     = "bind"
          source   = "local/user/rules"
          target   = "/app/user/rules"
          readonly = true
        }

        mount {
          type     = "bind"
          source   = "local/user/support"
          target   = "/app/user/support"
          readonly = true
        }

        mount {
          type     = "bind"
          source   = "local/data"
          target   = "/app/data"
          readonly = false
        }
      }

      env {
        INSTANCE_ID       = "${NOMAD_ALLOC_INDEX}"
        POSTGRES_DB       = "SitesIndex"
        POSTGRES_DB_PORT  = "5432"
        POSTGRES_SSL_MODE = "disable"
        TZ                = "UTC"
        MICROSERVICE_NAME = "crowler-api"
      }

      template {
        data            = file("./config.yaml")
        destination     = "local/config.yaml"
        once            = true
        left_delimiter  = "[[CROWLER_NOMAD["
        right_delimiter = "]CROWLER_NOMAD]]"
      }

      template {
        data        = local.common_env_template
        destination = "secrets/crowler-root.env"
        env         = true
        change_mode = "restart"
      }

      template {
        data        = local.crowler_db_credentials_template
        destination = "secrets/crowler-db.env"
        env         = true
        change_mode = "restart"
      }

      template {
        data        = local.database_host_template
        destination = "local/database.env"
        env         = true
        change_mode = "restart"
      }

      template {
        data        = local.prometheus_host_template
        destination = "local/prometheus.env"
        env         = true
        change_mode = "restart"
      }

      template {
        data        = ""
        destination = "local/user/agents/.nomad-keep"
        once        = true
      }

      template {
        data        = ""
        destination = "local/user/plugins/.nomad-keep"
        once        = true
      }

      template {
        data        = ""
        destination = "local/user/rules/.nomad-keep"
        once        = true
      }

      template {
        data        = ""
        destination = "local/user/support/.nomad-keep"
        once        = true
      }

      template {
        data        = ""
        destination = "local/data/.nomad-keep"
        once        = true
      }

      dynamic "template" {
        for_each = local.user_agents
        iterator = user_file

        content {
          data            = file("./user/agents/${user_file.value}")
          destination     = "local/user/agents/${user_file.value}"
          once            = true
          left_delimiter  = "[[CROWLER_NOMAD["
          right_delimiter = "]CROWLER_NOMAD]]"
        }
      }

      dynamic "template" {
        for_each = local.user_plugins
        iterator = user_file

        content {
          data            = file("./user/plugins/${user_file.value}")
          destination     = "local/user/plugins/${user_file.value}"
          once            = true
          left_delimiter  = "[[CROWLER_NOMAD["
          right_delimiter = "]CROWLER_NOMAD]]"
        }
      }

      dynamic "template" {
        for_each = local.user_rules
        iterator = user_file

        content {
          data            = file("./user/rules/${user_file.value}")
          destination     = "local/user/rules/${user_file.value}"
          once            = true
          left_delimiter  = "[[CROWLER_NOMAD["
          right_delimiter = "]CROWLER_NOMAD]]"
        }
      }

      dynamic "template" {
        for_each = local.user_support
        iterator = user_file

        content {
          data            = file("./user/support/${user_file.value}")
          destination     = "local/user/support/${user_file.value}"
          once            = true
          left_delimiter  = "[[CROWLER_NOMAD["
          right_delimiter = "]CROWLER_NOMAD]]"
        }
      }

      resources {
        cpu    = var.api_cpu
        memory = var.api_memory
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Events
  # ---------------------------------------------------------------------------
  group "events" {
    count = var.events_enabled ? 1 : 0

    network {
      mode = "bridge"

      port "http" {
        static = 8082
        to     = 8082
      }
    }

    service {
      name         = "crowler-events"
      provider     = "nomad"
      port         = "http"
      address_mode = "host"

      check {
        name     = "events-tcp"
        type     = "tcp"
        port     = "http"
        interval = "10s"
        timeout  = "3s"
      }
    }

    restart {
      attempts = 10
      interval = "10m"
      delay    = "10s"
      mode     = "delay"
    }

    task "crowler-events" {
      driver = "docker"

      config {
        image           = "zfpsystems/crowler-events:${var.crowler_version}"
        ports           = ["http"]
        readonly_rootfs = true

        mount {
          type     = "bind"
          source   = "local/config.yaml"
          target   = "/app/config.yaml"
          readonly = true
        }

        mount {
          type     = "bind"
          source   = "local/user/agents"
          target   = "/app/user/agents"
          readonly = true
        }

        mount {
          type     = "bind"
          source   = "local/user/plugins"
          target   = "/app/user/plugins"
          readonly = true
        }

        mount {
          type     = "bind"
          source   = "local/user/rules"
          target   = "/app/user/rules"
          readonly = true
        }

        mount {
          type     = "bind"
          source   = "local/user/support"
          target   = "/app/user/support"
          readonly = true
        }

        mount {
          type     = "bind"
          source   = "local/data"
          target   = "/app/data"
          readonly = false
        }
      }

      env {
        INSTANCE_ID       = "${NOMAD_ALLOC_INDEX}"
        POSTGRES_DB       = "SitesIndex"
        POSTGRES_DB_PORT  = "5432"
        POSTGRES_SSL_MODE = "disable"
        TZ                = "UTC"
        MICROSERVICE_NAME = "crowler-events"
      }

      template {
        data            = file("./config.yaml")
        destination     = "local/config.yaml"
        once            = true
        left_delimiter  = "[[CROWLER_NOMAD["
        right_delimiter = "]CROWLER_NOMAD]]"
      }

      template {
        data        = local.common_env_template
        destination = "secrets/crowler-root.env"
        env         = true
        change_mode = "restart"
      }

      template {
        data        = local.crowler_db_credentials_template
        destination = "secrets/crowler-db.env"
        env         = true
        change_mode = "restart"
      }

      template {
        data        = local.database_host_template
        destination = "local/database.env"
        env         = true
        change_mode = "restart"
      }

      template {
        data        = local.prometheus_host_template
        destination = "local/prometheus.env"
        env         = true
        change_mode = "restart"
      }

      template {
        data        = ""
        destination = "local/user/agents/.nomad-keep"
        once        = true
      }

      template {
        data        = ""
        destination = "local/user/plugins/.nomad-keep"
        once        = true
      }

      template {
        data        = ""
        destination = "local/user/rules/.nomad-keep"
        once        = true
      }

      template {
        data        = ""
        destination = "local/user/support/.nomad-keep"
        once        = true
      }

      template {
        data        = ""
        destination = "local/data/.nomad-keep"
        once        = true
      }

      dynamic "template" {
        for_each = local.user_agents
        iterator = user_file

        content {
          data            = file("./user/agents/${user_file.value}")
          destination     = "local/user/agents/${user_file.value}"
          once            = true
          left_delimiter  = "[[CROWLER_NOMAD["
          right_delimiter = "]CROWLER_NOMAD]]"
        }
      }

      dynamic "template" {
        for_each = local.user_plugins
        iterator = user_file

        content {
          data            = file("./user/plugins/${user_file.value}")
          destination     = "local/user/plugins/${user_file.value}"
          once            = true
          left_delimiter  = "[[CROWLER_NOMAD["
          right_delimiter = "]CROWLER_NOMAD]]"
        }
      }

      dynamic "template" {
        for_each = local.user_rules
        iterator = user_file

        content {
          data            = file("./user/rules/${user_file.value}")
          destination     = "local/user/rules/${user_file.value}"
          once            = true
          left_delimiter  = "[[CROWLER_NOMAD["
          right_delimiter = "]CROWLER_NOMAD]]"
        }
      }

      dynamic "template" {
        for_each = local.user_support
        iterator = user_file

        content {
          data            = file("./user/support/${user_file.value}")
          destination     = "local/user/support/${user_file.value}"
          once            = true
          left_delimiter  = "[[CROWLER_NOMAD["
          right_delimiter = "]CROWLER_NOMAD]]"
        }
      }

      resources {
        cpu    = var.events_cpu
        memory = var.events_memory
      }
    }
  }

  # ---------------------------------------------------------------------------
  # CROWler Engines
  # ---------------------------------------------------------------------------
  group "engine" {
    count = var.engine_count

    restart {
      attempts = 10
      interval = "10m"
      delay    = "10s"
      mode     = "delay"
    }

    task "crowler-engine" {
      driver = "docker"

      config {
        image = "zfpsystems/crowler-engine:${var.crowler_version}"

        mount {
          type     = "bind"
          source   = "local/config.yaml"
          target   = "/app/config.yaml"
          readonly = true
        }

        mount {
          type     = "bind"
          source   = "local/user/agents"
          target   = "/app/user/agents"
          readonly = true
        }

        mount {
          type     = "bind"
          source   = "local/user/plugins"
          target   = "/app/user/plugins"
          readonly = true
        }

        mount {
          type     = "bind"
          source   = "local/user/rules"
          target   = "/app/user/rules"
          readonly = true
        }

        mount {
          type     = "bind"
          source   = "local/user/support"
          target   = "/app/user/support"
          readonly = true
        }

        mount {
          type     = "bind"
          source   = "local/data"
          target   = "/app/data"
          readonly = false
        }
      }

      env {
        INSTANCE_ID                   = "${NOMAD_ALLOC_INDEX}"
        POSTGRES_DB                   = "SitesIndex"
        POSTGRES_DB_PORT              = "5432"
        POSTGRES_SSL_MODE             = "disable"
        CROWLER_MAIL_LISTENER_ENABLED = "false"
        TZ                            = "UTC"
        MICROSERVICE_NAME             = "crowler-engine-${NOMAD_ALLOC_INDEX}"
      }

      template {
        data            = file("./config.yaml")
        destination     = "local/config.yaml"
        once            = true
        left_delimiter  = "[[CROWLER_NOMAD["
        right_delimiter = "]CROWLER_NOMAD]]"
      }

      template {
        data        = local.common_env_template
        destination = "secrets/crowler-root.env"
        env         = true
        change_mode = "restart"
      }

      template {
        data        = local.crowler_db_credentials_template
        destination = "secrets/crowler-db.env"
        env         = true
        change_mode = "restart"
      }

      template {
        data        = local.database_host_template
        destination = "local/database.env"
        env         = true
        change_mode = "restart"
      }

      template {
        data        = local.selenium_host_template
        destination = "local/selenium.env"
        env         = true
        change_mode = "restart"
      }

      template {
        data        = local.prometheus_host_template
        destination = "local/prometheus.env"
        env         = true
        change_mode = "restart"
      }

      template {
        data        = ""
        destination = "local/user/agents/.nomad-keep"
        once        = true
      }

      template {
        data        = ""
        destination = "local/user/plugins/.nomad-keep"
        once        = true
      }

      template {
        data        = ""
        destination = "local/user/rules/.nomad-keep"
        once        = true
      }

      template {
        data        = ""
        destination = "local/user/support/.nomad-keep"
        once        = true
      }

      template {
        data        = ""
        destination = "local/data/.nomad-keep"
        once        = true
      }

      dynamic "template" {
        for_each = local.user_agents
        iterator = user_file

        content {
          data            = file("./user/agents/${user_file.value}")
          destination     = "local/user/agents/${user_file.value}"
          once            = true
          left_delimiter  = "[[CROWLER_NOMAD["
          right_delimiter = "]CROWLER_NOMAD]]"
        }
      }

      dynamic "template" {
        for_each = local.user_plugins
        iterator = user_file

        content {
          data            = file("./user/plugins/${user_file.value}")
          destination     = "local/user/plugins/${user_file.value}"
          once            = true
          left_delimiter  = "[[CROWLER_NOMAD["
          right_delimiter = "]CROWLER_NOMAD]]"
        }
      }

      dynamic "template" {
        for_each = local.user_rules
        iterator = user_file

        content {
          data            = file("./user/rules/${user_file.value}")
          destination     = "local/user/rules/${user_file.value}"
          once            = true
          left_delimiter  = "[[CROWLER_NOMAD["
          right_delimiter = "]CROWLER_NOMAD]]"
        }
      }

      dynamic "template" {
        for_each = local.user_support
        iterator = user_file

        content {
          data            = file("./user/support/${user_file.value}")
          destination     = "local/user/support/${user_file.value}"
          once            = true
          left_delimiter  = "[[CROWLER_NOMAD["
          right_delimiter = "]CROWLER_NOMAD]]"
        }
      }

      resources {
        cpu    = var.engine_cpu
        memory = var.engine_memory
      }
    }
  }
}
