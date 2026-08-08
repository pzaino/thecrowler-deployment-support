# Deploying The CROWler with HashiCorp Nomad

This directory provides the HashiCorp Nomad deployment backend for **The
CROWler**.

The jobspec consumes official pre-built CROWler images. It does not build
source code.

## Requirements

* HashiCorp Nomad **1.10 or newer**
* Nomad client nodes with the Docker task driver enabled
* Docker installed on Nomad client nodes
* `jq` on the operator machine
* access to a Nomad server
* registry access from Nomad clients

Nomad 1.10+ is required because the bundled PostgreSQL workflow uses dynamic
host volumes.

## Repository Root Is the Execution Root

Run every command from the repository root.

The Nomad backend intentionally uses Nomad HCL `file()` and `fileset()`
functions to read local deployment inputs while the CLI parses the job.

Canonical workspace:

```text
thecrowler-deployment-support/
├── .env
├── config.yaml
├── user/
│   ├── agents/
│   ├── plugins/
│   ├── rules/
│   └── support/
└── nomad/
    ├── crowler.nomad.hcl
    ├── deploy.sh
    ├── bootstrap-env.sh
    ├── preflight.sh
    ├── values.example.hcl
    └── volumes/
        └── crowler-db-data.hcl
```

Do not `cd nomad` before running commands.

## Architecture

The default job contains:

* bundled PostgreSQL
* two CROWler Engines
* two VDIs
* API
* Events
* Jaeger
* optional Prometheus Pushgateway

Nomad native service discovery is used so the backend does not require Consul.

### Engine to VDI Assignment

Each local VDI listens on host port `4444`.

Because all local VDIs use the same port, the VDI task group uses
`distinct_hosts`. A deployment with `vdi_count = 2` therefore needs at least
two eligible Nomad client nodes.

Engine allocations use Nomad's rendezvous-hash service selection to choose one
VDI. The selected VDI remains stable for that allocation unless pool membership
changes.

## 1. Prepare Root Deployment Inputs

```bash
cp common/env/env_template .env
```

Choose one configuration model:

```bash
cp common/config/config.default config.yaml
```

or:

```bash
cp common/config/config.default.remote config.yaml
```

Edit `.env` and `config.yaml`.

## 2. Check the Runtime Config Contract

For local VDI discovery, the effective CROWler config must use:

```yaml
vdi:
  - host: ${SELENIUM_HOST}
    port: 4444
```

See:

```text
nomad/config-runtime-contract.md
```

The preflight script checks this for local configurations.

## 3. Optional Non-Secret Nomad Overrides

Defaults are already declared in the jobspec.

For deployment-specific settings:

```bash
cp nomad/values.example.hcl nomad/values.hcl
```

Edit `nomad/values.hcl`.

Do **not** put credentials in that file.

Common settings include:

```hcl
engine_count = 4
vdi_count    = 4

database_enabled = true
jaeger_enabled   = true
```

## 4. Configure Nomad CLI Access

Set normal Nomad CLI variables as required by your cluster, for example:

```bash
export NOMAD_ADDR="https://nomad.example.internal:4646"
export NOMAD_NAMESPACE="default"
```

If ACLs are enabled, provide your operator token through the normal Nomad
mechanism.

## 5. Create the PostgreSQL Volume

When using bundled PostgreSQL:

```bash
./nomad/deploy.sh volume-create
```

This creates the dynamic host volume:

```text
crowler-db-data
```

using Nomad's built-in `mkdir` host-volume plugin.

This is node-local storage. For production databases requiring node
independence or stronger durability, use external PostgreSQL or replace the
volume strategy with suitable shared/CSI-backed storage.

Do not repeatedly create new database volumes.

## 6. Synchronize `.env`

```bash
./nomad/deploy.sh env-sync
```

The script:

1. reads root `.env`
2. excludes values controlled by Nomad service discovery
3. writes the remaining values to the encrypted Nomad Variable:

```text
nomad/jobs/crowler/env
```

The script uses stdin JSON rather than placing secret values in Nomad CLI
arguments.

Nomad Variables are appropriate for small workload configuration and secrets,
but they are not a replacement for Vault in higher-security environments.

## 7. Validate

```bash
./nomad/deploy.sh validate
```

This runs:

```text
repository-root preflight
nomad fmt -check
nomad job validate
```

## 8. Plan

```bash
./nomad/deploy.sh plan
```

`plan` synchronizes `.env` first.

Review the scheduler plan before applying it.

## 9. Deploy

```bash
./nomad/deploy.sh run
```

`run` synchronizes `.env` and submits or updates the job.

## 10. Inspect

```bash
./nomad/deploy.sh status
./nomad/deploy.sh allocations
```

Useful native commands:

```bash
nomad job status crowler
nomad job allocs crowler
nomad alloc status ALLOCATION_ID
nomad alloc logs ALLOCATION_ID TASK
nomad service list
nomad service info crowler-vdi
```

## User Content

The backend preserves the deployment contract:

```text
user/agents   -> /app/user/agents
user/plugins  -> /app/user/plugins
user/rules    -> /app/user/rules
user/support  -> /app/user/support
```

Unlike Compose, Nomad does not bind the repository directories from every
client node.

Instead, HCL `fileset()` enumerates direct files on the operator machine and
`file()` embeds their contents into task template blocks when the job is
parsed. Nomad renders those files into each allocation, then the Docker task
driver bind-mounts the allocation-local directories read-only into the
container.

This means the source repository only needs to exist on the machine from which
you run the Nomad CLI.

For large datasets, binaries, or frequently changing support data, use
artifact/object storage or a suitable shared volume rather than embedding them
in a Nomad jobspec.

## Root `config.yaml`

Engine, API, and Events receive:

```text
/app/config.yaml
```

The file is read from root `./config.yaml` by the local Nomad CLI parser and
rendered into each allocation.

Custom template delimiters are used so CROWler rules/configuration containing
Go-template-style `{{ ... }}` text are not accidentally evaluated by Nomad.

## Service Discovery

The backend uses Nomad native service discovery for:

```text
crowler-db
crowler-vdi
crowler-jaeger-otlp
crowler-jaeger-ui
crowler-push-gateway
crowler-api
crowler-events
```

This intentionally avoids making Consul mandatory for the default deployment.

Native Nomad service discovery and Nomad Variables create a runtime dependency
on the Nomad servers for template updates. For larger production environments,
Consul and Vault remain valid future integrations.

## Networking

Static host ports preserve the existing CROWler configuration contract:

| Component | Host port |
| --- | ---: |
| PostgreSQL | 5432 |
| VDI Selenium | 4444 |
| VDI manager | 4445 |
| VNC | 5900 |
| noVNC | 7900 |
| CDP | 9222 |
| API | 8080 |
| Events | 8082 |
| Jaeger UI | 16686 |
| Pushgateway | 9091 |

Jaeger OTLP uses a dynamically allocated Nomad host port because its endpoint
is injected directly into VDI through service discovery.

Do not expose management ports beyond trusted networks without an explicit
security design.

## PostgreSQL Persistence

The bundled volume specification uses a dynamic host volume.

The default `mkdir` volume is local to one Nomad client. The jobspec requests
`single-node-single-writer` access and sticky placement.

This does not turn local disk into highly available storage.

## Engine Network Capabilities

The Compose backend explicitly adds `NET_ADMIN` and `NET_RAW`.

The Nomad backend does **not** request additional capabilities by default.
CROWler images run non-root, and Nomad's Docker driver capability policy is
controlled by each client. Nomad also documents Docker limitations around
expanding capabilities for non-root tasks.

The official Engine image already applies file capabilities to `nmap`.
Validate the network-discovery modes you need in staging.

If a specific CROWler operation proves to require additional container
capabilities, configure the Nomad Docker client allowlist deliberately and
review the security implications rather than enabling privileged mode.

## External PostgreSQL

In `nomad/values.hcl`:

```hcl
database_enabled = false
external_db_host = "postgres.example.internal"
```

The configured CROWler database credentials still come from root `.env`.

## External Selenium / VDI

```hcl
vdi_count              = 0
external_selenium_host = "selenium.example.internal"
```

The effective CROWler config must still use `${SELENIUM_HOST}`.

## Pushgateway

Pushgateway is disabled by default.

To enable Nomad-managed Pushgateway:

```hcl
pushgateway_enabled = true
```

and configure CROWler with:

```yaml
prometheus:
  enabled: true
  host: ${PROMETHEUS_HOST}
  port: 9091
```

## Stop

```bash
./nomad/deploy.sh stop
```

This stops the job without purging it.

Stopping the job does not imply deleting the PostgreSQL volume.

## Safety

Do not:

* delete the database volume as routine troubleshooting
* put passwords/tokens in `nomad/values.hcl`
* use privileged containers by default
* replace official images with local builds
* assume local host volumes are highly available
