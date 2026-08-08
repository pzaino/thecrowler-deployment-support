# AI Agent Instructions

This repository deploys pre-built CROWler artifacts.

## Repository Root Is the Execution Root

All deployment commands and tools must be run from the repository root.

Canonical root-level deployment paths:

```text
.env
config.yaml
docker-compose.yml
user/
```

Do not change into backend subdirectories before running generators,
validation, or deployment commands unless a backend document explicitly says
otherwise.

Relative deployment paths are intentionally repository-root relative.

## Repository Purpose

Do not build The CROWler from source in this repository.

Source development belongs in:

https://github.com/pzaino/thecrowler

## Official Images

Use:

* `zfpsystems/crowler-db`
* `zfpsystems/crowler-engine`
* `zfpsystems/crowler-vdi`
* `zfpsystems/crowler-api`
* `zfpsystems/crowler-events`

Do not introduce local image builds unless explicitly requested.

## Supported Backends

* Docker Compose: `docker-compose/README.md`
* Docker Swarm: `docker-swarm/README.md`
* Kubernetes: `kubernetes/README.md`
* Helm: `helm/README.md`

## Runtime Configuration

Engine, API, and Events require:

```text
/app/config.yaml
```

Create root `config.yaml` from exactly one of:

* `common/config/config.default`
* `common/config/config.default.remote`

Do not silently choose between them.

## User Deployment Content

Canonical host-side layout:

```text
user/
├── agents/
├── plugins/
├── rules/
└── support/
```

Canonical runtime layout:

```text
/app/user/agents
/app/user/plugins
/app/user/rules
/app/user/support
```

Never mount over the built-in `/app/agents`, `/app/plugins`, `/app/rules`, or
`/app/support` directories.

### Docker Compose

Use read-only repository-root bind mounts from `./user/...` to `/app/user/...`.

### Docker Swarm

Do not use node-local `./user/...` bind mounts.

Use content-hashed Docker Swarm configs for direct user files so Swarm can
distribute them to scheduled tasks.

Swarm configs:

* are immutable
* are not secrets
* are limited to 500 KiB each

A changed file must receive a new config object name while retaining its
stable in-container target.

Larger user content requires an external/shared Swarm volume.


CROWler images intended for this Swarm deployment contract must provide
`/app/user/agents`, `/app/user/plugins`, `/app/user/rules`, and
`/app/user/support` as readable directories.

## Credentials

Never invent credentials.

Never commit `.env`, production Secrets, private Helm values, or other
credentials.

Do not place credentials inside user-content Docker configs.

## Validation

Docker Compose:

```bash
docker compose config
```

Docker Swarm:

```bash
set -a
. ./.env
set +a
docker stack config -c docker-compose.yml
```

Kubernetes:

```bash
kubectl apply --dry-run=client -R -f kubernetes/base/
```

Helm:

```bash
helm lint helm/thecrowler
helm template crowler helm/thecrowler --namespace crowler
```

Validation does not prove runtime health.

## Agent Skills

Task-specific instructions are under:

```text
.agents/skills/
```
