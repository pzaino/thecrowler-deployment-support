---
name: deploy-docker-compose
description: Deploy, configure, scale, validate, or troubleshoot The CROWler with Docker Compose using official zfpsystems images. Use for single-host CROWler Docker Compose deployment, topology generation, image version selection, runtime config.yaml delivery, environment configuration, validation, startup, shutdown, logs, and health checks. Do not use for Docker Swarm stack deployment or for building CROWler images from source.
compatibility: Requires thecrowler-deployment-support, Bash, Docker, and Docker Compose v2.
metadata:
  project: thecrowler
  repository: pzaino/thecrowler-deployment-support
  deployment-backend: docker-compose
---

# Deploy The CROWler with Docker Compose

## Sources of Truth

Inspect:

* `docker-compose/generate-docker-compose.sh`
* `docker-compose/README.md`
* `common/env/env_template`
* `common/config/config.default`
* `common/config/config.default.remote`
* `AGENTS.md`

## Required Deployment Files

A normal deployment workspace requires:

```text
.env
config.yaml
docker-compose.yml
```

Before generation:

1. create `.env` from `common/env/env_template`
2. create `config.yaml` from exactly one of:
   * `common/config/config.default`
   * `common/config/config.default.remote`
3. edit both files
4. generate `docker-compose.yml`

Do not silently select local versus remote configuration.

## Runtime Config Contract

Engine, API, and Events require:

`/app/config.yaml`

The generator must deliver the deployment-level `config.yaml` using the
top-level Docker config:

`crowler_config`

Do not use the image-baked config when a deployment-level config is supplied.

Do not attach `crowler_config` to DB, VDI, Jaeger, or Pushgateway.

## Official Images

Use:

* `zfpsystems/crowler-db`
* `zfpsystems/crowler-engine`
* `zfpsystems/crowler-vdi`
* `zfpsystems/crowler-api`
* `zfpsystems/crowler-events`

Do not add local `build:` directives.

## Generate

Prefer non-interactive execution:

```bash
./docker-compose/generate-docker-compose.sh \
  -e=2 \
  -v=2 \
  --prom=yes \
  --pg=yes
```

Use `--config=PATH` or `--env-file=PATH` only when the deployment does not use
the default root-level `config.yaml` and `.env`.

## Validate

```bash
docker compose config
```

Verify:

* expected images and tags
* Engine and VDI counts
* valid Engine-to-VDI mapping
* `crowler_config`
* `/app/config.yaml` targets
* networks
* volumes
* ports
* optional services

## Start

When requested:

```bash
docker compose pull
docker compose up -d
docker compose ps
```

## Safety

Never:

* overwrite user credentials
* overwrite `config.yaml` without authorization
* delete persistent volumes routinely
* use `docker compose down -v` unless persistent deletion is explicitly intended
* fall back to local builds because an image cannot be pulled
