# Nomad Runtime Configuration Contract

Nomad keeps the same root-level CROWler configuration model used by the other
deployment backends:

```text
./config.yaml
```

The job ships this file into Engine, API, and Events at:

```text
/app/config.yaml
```

## Database

The normal local CROWler configuration already uses:

```yaml
database:
  host: ${DOCKER_DB_HOST}
  port: 5432
```

Nomad sets `DOCKER_DB_HOST` from native Nomad service discovery when bundled
PostgreSQL is enabled.

When bundled PostgreSQL is disabled, set `external_db_host` in
`nomad/values.hcl`.

## VDI

For Nomad service discovery, the effective CROWler configuration must use:

```yaml
vdi:
  - type: chrome
    host: ${SELENIUM_HOST}
    port: 4444
```

Nomad assigns each Engine allocation a stable VDI instance using rendezvous
hashing and sets `SELENIUM_HOST`.

The current deployment `config.default` may still contain:

```yaml
host: localhost
```

If so, change that line in the root `config.yaml` before deploying with Nomad.
`nomad/preflight.sh` refuses to continue when a local VDI section still uses a
literal host.

When `vdi_count = 0`, set `external_selenium_host` in `nomad/values.hcl`.

## Prometheus Pushgateway

The CROWler reads the Pushgateway address from:

```yaml
prometheus:
  host: ...
  port: 9091
```

If you enable the Nomad Pushgateway and want CROWler services to discover it,
use:

```yaml
prometheus:
  enabled: true
  host: ${PROMETHEUS_HOST}
  port: 9091
```

The Nomad job sets `PROMETHEUS_HOST` from native service discovery.

Pushgateway is disabled by default in the Nomad values because the current
generic CROWler deployment config uses a literal host.

## User Content

The effective configuration should load both built-in and deployment-specific
paths:

```text
/app/agents + /app/user/agents
/app/plugins + /app/user/plugins
/app/rules + /app/user/rules
/app/support + /app/user/support
```

The exact `support` configuration mechanism depends on the corresponding
CROWler core support-path changes.
