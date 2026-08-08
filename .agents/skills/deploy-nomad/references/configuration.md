# HashiCorp Nomad Deployment Reference

## Repository Root

Commands execute from:

```text
thecrowler-deployment-support/
```

Canonical inputs:

```text
.env
config.yaml
user/
```

## Jobspec

```text
nomad/crowler.nomad.hcl
```

## Optional Values

```text
nomad/values.hcl
```

Create from:

```text
nomad/values.example.hcl
```

No secrets belong in this file.

## Minimum Nomad Version

```text
1.10+
```

Required for dynamic host volumes used by bundled PostgreSQL.

## Root Environment

Stored at:

```text
nomad/jobs/crowler/env
```

Synchronize with:

```bash
./nomad/bootstrap-env.sh
```

## Runtime Config

Host:

```text
./config.yaml
```

Container:

```text
/app/config.yaml
```

## User Content

```text
user/agents   -> /app/user/agents
user/plugins  -> /app/user/plugins
user/rules    -> /app/user/rules
user/support  -> /app/user/support
```

Source files are read by the local Nomad CLI HCL parser.

## Native Services

```text
crowler-db
crowler-vdi
crowler-api
crowler-events
crowler-jaeger-otlp
crowler-jaeger-ui
crowler-push-gateway
```

## Ports

```text
PostgreSQL       5432
Selenium         4444
VDI manager      4445
VNC              5900
noVNC            7900
CDP              9222
API              8080
Events           8082
Jaeger UI       16686
Pushgateway      9091
```

Jaeger OTLP uses a dynamic host port.

## VDI

Local VDI service discovery supplies:

```text
SELENIUM_HOST
```

CROWler effective configuration must reference it.

Local VDI allocations use static Selenium port 4444 and `distinct_hosts`.

## Database

Bundled DB:

```text
database_enabled=true
database_volume_source=crowler-db-data
```

External:

```text
database_enabled=false
external_db_host=<hostname-or-address>
```

## Storage

Volume spec:

```text
nomad/volumes/crowler-db-data.hcl
```

Access mode:

```text
single-node-single-writer
```

Plugin:

```text
mkdir
```

This is node-local persistence.

## Image Versions

Root `.env` supplies:

```text
CROWLER_VERSION
CROWLER_VDI_VERSION
```

`nomad/deploy.sh` exports them as HCL input variables.

## Commands

```bash
./nomad/deploy.sh validate
./nomad/deploy.sh env-sync
./nomad/deploy.sh volume-create
./nomad/deploy.sh plan
./nomad/deploy.sh run
./nomad/deploy.sh status
./nomad/deploy.sh allocations
./nomad/deploy.sh stop
```
