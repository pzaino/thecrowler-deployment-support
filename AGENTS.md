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
* HashiCorp Nomad: `nomad/README.md`

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

Never mount over built-in `/app/agents`, `/app/plugins`, `/app/rules`, or
`/app/support`.

### Docker Compose

Use read-only repository-root bind mounts.

### Docker Swarm

Do not use node-local `./user/...` bind mounts. Use versioned Swarm configs for
small direct user files.

### HashiCorp Nomad

Do not require `user/` directories on every Nomad client.

The Nomad CLI must be run from the repository root so HCL `file()` and
`fileset()` can consume root `config.yaml` and `user/*` locally.

Render those files into allocation-local directories and mount the resulting
paths at `/app/user/...`.

Use native Nomad service discovery by default; do not make Consul mandatory.

Use Nomad Variables at:

```text
nomad/jobs/crowler/env
```

for the root `.env` values imported by `nomad/bootstrap-env.sh`.

Bundled PostgreSQL uses a dynamic host volume. Do not describe local dynamic
host volumes as highly available storage.

Local VDI discovery requires the effective CROWler config to consume:

```text
SELENIUM_HOST
```

Do not silently deploy `localhost` as the VDI host in a multi-node Nomad
deployment.

## Credentials

Never invent credentials.

Never commit `.env`, production Secrets, private Helm values, or credentials.

Do not put credentials inside `user/`.

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

Nomad:

```bash
./nomad/deploy.sh validate
./nomad/deploy.sh plan
```

Validation does not prove runtime health.

## Agent Skills

Task-specific instructions are under:

```text
.agents/skills/
```
