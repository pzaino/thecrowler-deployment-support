# Deploying The CROWler with Docker Compose

This directory contains the Docker Compose deployment tooling for **The
CROWler**.

The deployment uses official pre-built CROWler images and does not build the
project from source.

## Requirements

You need:

* Docker
* Docker Compose v2
* Bash

## Quick Start

Run these commands from the repository root.

### 1. Create the environment file

```bash
cp common/env/env_template .env
```

Edit `.env` and configure your passwords and image versions.

### 2. Create `config.yaml`

Choose one configuration model.

For a full local CROWler configuration:

```bash
cp common/config/config.default config.yaml
```

For remote configuration bootstrap:

```bash
cp common/config/config.default.remote config.yaml
```

Edit the resulting `config.yaml`.

Do not create both. The selected file becomes the runtime configuration
delivered to CROWler Engine, API, and Events as `/app/config.yaml`.

### 3. Generate the deployment

From the repository root:

```bash
./docker-compose/generate-docker-compose.sh
```

Or non-interactively:

```bash
./docker-compose/generate-docker-compose.sh \
  -e=2 \
  -v=2 \
  --prom=yes \
  --pg=yes
```

This creates:

```text
docker-compose.yml
```

The normal deployment workspace is therefore:

```text
.env
config.yaml
docker-compose.yml
```

### 4. Validate

```bash
docker compose config
```

### 5. Pull and start

```bash
docker compose pull
docker compose up -d
```

### 6. Inspect

```bash
docker compose ps
docker compose logs -f
```

## CROWler Runtime Configuration

The generator declares:

```yaml
configs:
  crowler_config:
    file: "config.yaml"
```

and attaches that configuration to:

* `crowler-api`
* `crowler-events`
* every `crowler-engine-*`

at:

```text
/app/config.yaml
```

The DB, VDI, Jaeger, and Pushgateway services do not receive this config.

You may use another file name:

```bash
./docker-compose/generate-docker-compose.sh \
  --config=config.production.yaml \
  -e=2 \
  -v=2 \
  --prom=yes \
  --pg=yes
```

The generator refuses to proceed when Engine, API, or Events are enabled and
the selected configuration file does not exist.

## Environment File

The default environment file is:

```text
.env
```

Use another file with:

```bash
--env-file=path/to/file
```

The generated service `env_file` references the same path.

## Official Images

| Component | Image |
| --- | --- |
| Database | `zfpsystems/crowler-db` |
| Engine | `zfpsystems/crowler-engine` |
| VDI | `zfpsystems/crowler-vdi` |
| API | `zfpsystems/crowler-api` |
| Events | `zfpsystems/crowler-events` |

`CROWLER_VERSION` controls DB, Engine, API, and Events.

`CROWLER_VDI_VERSION` controls VDI independently.

## Generator Options

Run:

```bash
./docker-compose/generate-docker-compose.sh --help
```

Important options include:

```text
--engine_count=N
--engine=N
-e=N
--vdi_count=N
--vdi=N
-v=N
--prometheus=yes|no
--prom=yes|no
--postgres=yes|no
--pg=yes|no
--no_api
--no_events
--no_jaeger
--cpu_limit=N
--cpu_limit_engine=N
--cpu_limit_vdi=N
--cpu_limit_mng=N
--cpu_limit_tlm=N
--mem_limit_engine=PERCENT
--mem_limit_vdi=PERCENT
--mem_limit_mng=PERCENT
--mem_limit_tlm=PERCENT
--config=PATH
--env-file=PATH
--swarm=yes|no
```

## Engine and VDI Mapping

When local VDIs are generated, Engines are assigned to VDIs in round-robin
order.

For example, four Engines and two VDIs produce:

```text
engine 1 -> crowler-vdi-1
engine 2 -> crowler-vdi-2
engine 3 -> crowler-vdi-1
engine 4 -> crowler-vdi-2
```

Every Engine is connected to all generated VDI networks.

`DOCKER_SELENIUM_HOST` may override the generated default.

## Persistent Volumes

The generated deployment may contain:

```text
db_data
engine_data
api_data
events_data
```

Do not remove persistent volumes as a routine troubleshooting step.

## Stop the Deployment

```bash
docker compose down
```

Do not add `-v` unless persistent data deletion is explicitly intended.

## Docker Swarm

For Docker Swarm use:

[docker-swarm/README.md](../docker-swarm/README.md)
