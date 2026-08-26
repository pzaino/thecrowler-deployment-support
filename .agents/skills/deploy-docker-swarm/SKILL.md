---
name: deploy-docker-swarm
description: Deploy, configure, scale, validate, update, inspect, or troubleshoot The CROWler with Docker Swarm using official zfpsystems images. Use for stack generation, multi-node deployment, overlay networking, runtime config.yaml distribution, versioned user agents/plugins/rules/support distribution, service inspection, resource limits, storage planning, updates, and troubleshooting. Do not use for ordinary single-host Docker Compose deployment or for building CROWler images from source.
compatibility: Requires thecrowler-deployment-support, Bash, Docker Engine with Swarm support, access to a Swarm manager, and sha256sum or shasum.
metadata:
  project: thecrowler
  repository: pzaino/thecrowler-deployment-support
  deployment-backend: docker-swarm
---

# Deploy The CROWler with Docker Swarm

## Execution Root

All commands must run from the repository root.

Expected root-level paths include:

```text
.env
config.yaml
docker-compose.yml
user/
```

Never `cd docker-compose` or `cd docker-swarm` before invoking deployment
commands.

## Sources of Truth

Inspect:

* `docker-swarm/generate-docker-compose.sh`
* `docker-swarm/README.md`
* `user/README.md`
* `common/env/env_template`
* `common/config/config.default`
* `common/config/config.default.remote`
* `AGENTS.md`

The dedicated Swarm generator is authoritative for Swarm. Do not use the
ordinary Compose generator as a substitute, because Swarm must content-hash
runtime configuration and user content into immutable Docker Config objects.

## Runtime Configuration

Engine, API, and Events require:

```text
/app/config.yaml
```

The generator content-hashes `config.yaml` because Docker Swarm configs are
immutable.

A changed `config.yaml` must result in a new Swarm config object while keeping
the same `/app/config.yaml` target.

## User Content

Canonical host paths:

```text
user/agents
user/plugins
user/rules
user/support
```

Canonical container targets:

```text
/app/user/agents
/app/user/plugins
/app/user/rules
/app/user/support
```

Never emit node-local bind mounts for these paths in Swarm mode.

Instead, the generator must:

1. enumerate direct, non-hidden regular files
2. reject filenames outside `[A-Za-z0-9._-]+`
3. reject files larger than 500 KiB
4. hash each file's content
5. declare a versioned top-level Swarm config
6. attach it to Engine, API, and Events at the stable `/app/user/...` target

Do not put secrets in Docker configs.

For files larger than 500 KiB, require an external/shared Swarm volume rather
than silently falling back to a node-local bind mount.

Require the CROWler images to provide the stable parent directories:

```text
/app/user/agents
/app/user/plugins
/app/user/rules
/app/user/support
```

## Environment

Before validation or deployment:

```bash
set -a
. ./.env
set +a
```

## Generate

```bash
./docker-swarm/generate-docker-compose.sh \
  -e=2 \
  -v=2 \
  --prom=yes \
  --pg=yes \
  --swarm=yes
```

## Validate

```bash
bash ./scripts/validate-deployment-support.sh swarm
docker stack config -c docker-compose.yml
```

Verify:

* no `./user/...` bind mounts
* hashed runtime config
* hashed user configs
* stable `/app/config.yaml`
* stable `/app/user/...` targets
* overlay networks
* resource limits
* volumes
* ports
* requested optional services

## Deploy

```bash
docker stack deploy \
  -c docker-compose.yml \
  --resolve-image always \
  crowler
```

## Inspect

```bash
docker stack services crowler
docker stack ps crowler --no-trunc
docker config ls --filter label=com.docker.stack.namespace=crowler
```

## Storage

Local Docker volumes remain node-local.

Do not assume PostgreSQL data follows a rescheduled task.

## Safety

Never:

* initialize or recreate a Swarm without explicit intent
* overwrite `.env` or `config.yaml`
* delete persistent volumes routinely
* place secrets in user-content Swarm configs
* fall back to node-local user-content bind mounts on worker nodes
