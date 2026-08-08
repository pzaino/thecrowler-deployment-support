# Optional non-secret overrides for nomad/crowler.nomad.hcl.
#
# Copy this file if you want local deployment-specific overrides:
#
#   cp nomad/values.example.hcl nomad/values.hcl
#
# nomad/deploy.sh automatically uses nomad/values.hcl when present.
# Do not put passwords, tokens, or private keys in this file.

datacenters = ["dc1"]
namespace   = "default"

engine_count = 2
vdi_count    = 2

database_enabled    = true
api_enabled         = true
events_enabled      = true
jaeger_enabled      = true
pushgateway_enabled = false

# Required only when the corresponding local service is disabled.
external_db_host         = ""
external_selenium_host   = ""
external_prometheus_host = ""

database_volume_source = "crowler-db-data"

# Nomad CPU values are MHz shares; memory values are MiB.
db_cpu    = 1000
db_memory = 2048

api_cpu    = 500
api_memory = 1024

events_cpu    = 500
events_memory = 1024

engine_cpu    = 1000
engine_memory = 2048

vdi_cpu    = 2000
vdi_memory = 4096

jaeger_cpu    = 500
jaeger_memory = 1024

pushgateway_cpu    = 250
pushgateway_memory = 512
