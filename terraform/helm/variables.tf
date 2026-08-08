variable "kubeconfig_path" {
  description = "Kubeconfig used by the Kubernetes and Helm providers."
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Optional kubeconfig context."
  type        = string
  default     = ""
}

variable "namespace" {
  type    = string
  default = "crowler"
}

variable "create_namespace" {
  type    = bool
  default = true
}

variable "release_name" {
  type    = string
  default = "crowler"
}

variable "crowler_version" {
  type    = string
  default = "2.0.3"
}

variable "vdi_version" {
  type    = string
  default = "4.28.1-20260807"
}

variable "engine_replicas" {
  type    = number
  default = 2
}

variable "vdi_replicas" {
  type    = number
  default = 2
}

variable "api_replicas" {
  type    = number
  default = 1
}

variable "events_replicas" {
  type    = number
  default = 1
}

variable "database_enabled" {
  type    = bool
  default = true
}

variable "external_db_host" {
  type    = string
  default = ""
}

variable "database_storage_size" {
  type    = string
  default = "10Gi"
}

variable "database_storage_class" {
  type    = string
  default = ""
}

variable "jaeger_enabled" {
  type    = bool
  default = true
}

variable "pushgateway_enabled" {
  type    = bool
  default = true
}

variable "kubernetes_secret_json" {
  description = "Root .env JSON map written through kubernetes_secret_v1.data_wo."
  type        = string
  sensitive   = true

  validation {
    condition     = can(tomap(jsondecode(var.kubernetes_secret_json)))
    error_message = "kubernetes_secret_json must be a JSON object."
  }
}

variable "kubernetes_secret_revision" {
  description = "Non-secret revision marker for the write-only Kubernetes Secret."
  type        = number

  validation {
    condition     = var.kubernetes_secret_revision >= 1
    error_message = "kubernetes_secret_revision must be >= 1."
  }
}

variable "atomic" {
  type    = bool
  default = true
}

variable "timeout_seconds" {
  type    = number
  default = 600
}
