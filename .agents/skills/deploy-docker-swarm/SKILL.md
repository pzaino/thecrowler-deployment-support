---
name: deploy-docker-swarm
description: Deploy, configure, scale, validate, update, inspect, or troubleshoot The CROWler with Docker Swarm using official zfpsystems images. Use for CROWler Swarm stack generation, multi-node deployment, overlay networking, runtime config.yaml distribution, service and task inspection, resource limits, persistent-storage planning, updates, and troubleshooting. Do not use for ordinary single-host Docker Compose deployment or for building CROWler images from source.
compatibility: Requires thecrowler-deployment-support, Bash, Docker Engine with Swarm support, and access to a Swarm manager.
metadata:
  project: thecrowler
  repository: pzaino/thecrowler-deployment-support
  deployment-backend: docker-swarm
---

# Deploy The CROWler with Docker Swarm

## Sources of Truth

Inspect:

* `docker-compose/generate-docker-compose.sh`
* `docker-swarm/README.md`
* `common/env/env_template`
* `common/config/config.default`
* `common/config/config.default.remote`
* `AGENTS.md`

## Required Deployment Files

A normal Swarm deployment workspace requires:

```text
.env
config.yaml
docker-compose.yml
```

Create `config.yaml` from exactly one of:

* `common/config/config.default`
* `common/config/config.default.remote`

Do not silently choose the mode.

## Runtime Config Contract

Engine, API, and Events require:

`/app/config.yaml`

The generated stack must use Docker `configs` to distribute the selected
deployment-level `config.yaml`.

Do not replace this with a node-local bind mount unless explicitly required.

## Generate

Export the deployment environment on the manager:

```bash
set -a
. ./.env
set +a
```

Generate:

```bash
./docker-compose/generate-docker-compose.sh \
  -e=2 \
  -v=2 \
  --prom=yes \
  --pg=yes \
  --swarm=yes
```

## Validate

```bash
docker stack config -c docker-compose.yml
```

Verify:

* official images and tags
* Engine and VDI counts
* Engine-to-VDI mapping
* overlay networks
* `crowler_config`
* `/app/config.yaml` targets
* resource limits
* persistent volumes
* optional services
* ports

## Deploy

```bash
docker stack deploy \
  -c docker-compose.yml \
  --resolve-image always \
  crowler
```

Use `--with-registry-auth` only when required.

## Inspect

```bash
docker stack services crowler
docker stack ps crowler --no-trunc
```

For failures:

```bash
docker service ps SERVICE --no-trunc
docker service logs SERVICE
```

## Storage

Local Docker volumes are node-local.

Do not assume PostgreSQL data follows a rescheduled task.

## Safety

Never:

* initialize or recreate a Swarm without explicit intent
* delete persistent volumes routinely
* overwrite `config.yaml` or `.env`
* replace official images with source builds because workers cannot pull them
