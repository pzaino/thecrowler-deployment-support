variable "nomad_address" {
  description = "Nomad HTTP(S) API address."
  type        = string
  default     = "http://127.0.0.1:4646"
}

variable "nomad_region" {
  description = "Nomad region. Empty uses the provider/NOMAD_REGION default."
  type        = string
  default     = ""
}

variable "namespace" {
  description = "Existing Nomad namespace for the CROWler job and variable."
  type        = string
  default     = "default"
}

variable "datacenters" {
  description = "Nomad datacenters eligible for the CROWler job."
  type        = list(string)
  default     = ["dc1"]
}

variable "crowler_version" {
  description = "CROWler image version. terraform/run.sh supplies root CROWLER_VERSION."
  type        = string
  default     = "latest"
}

variable "vdi_version" {
  description = "VDI image version. terraform/run.sh supplies root CROWLER_VDI_VERSION."
  type        = string
  default     = "4.28.1-20260819"
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

variable "manage_database_volume" {
  description = "Create the bundled PostgreSQL dynamic host volume through Terraform."
  type        = bool
  default     = true
}

variable "database_volume_source" {
  type    = string
  default = "crowler-db-data"
}

variable "database_volume_capacity" {
  description = "Requested dynamic host volume capacity."
  type        = string
  default     = "10GiB"
}

variable "database_volume_mode" {
  description = "mkdir plugin filesystem mode."
  type        = string
  default     = "0777"
}

variable "nomad_env_json" {
  description = "Root .env JSON map written through nomad_variable.items_wo."
  type        = string
  sensitive   = true

  validation {
    condition     = can(tomap(jsondecode(var.nomad_env_json)))
    error_message = "nomad_env_json must be a JSON object."
  }
}

variable "nomad_env_revision" {
  description = "Non-secret revision marker for the write-only Nomad Variable."
  type        = number

  validation {
    condition     = var.nomad_env_revision >= 1
    error_message = "nomad_env_revision must be >= 1."
  }
}

variable "detach" {
  description = "Return immediately after Nomad accepts an update."
  type        = bool
  default     = false
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
