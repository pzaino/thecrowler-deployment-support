# AI Agent Instructions

This repository deploys pre-built CROWler artifacts.

## Repository Purpose

Do not build The CROWler from source in this repository.

Source development belongs in:

https://github.com/pzaino/thecrowler

This repository is responsible for deployment tooling, deployment
configuration, deployment documentation, and orchestration definitions that
consume the official pre-built CROWler artifacts.

## Official Images

Use the official CROWler images:

* `zfpsystems/crowler-db`
* `zfpsystems/crowler-engine`
* `zfpsystems/crowler-vdi`
* `zfpsystems/crowler-api`
* `zfpsystems/crowler-events`

unless the user explicitly requests another registry or image source.

Do not introduce local `build:` directives into deployment definitions.

Official CROWler images are multi-platform. Do not force `linux/amd64` unless
there is an explicit platform requirement.

## Deployment Documentation

Currently supported:

* Docker Compose: `docker-compose/README.md`
* Docker Swarm: `docker-swarm/README.md`

Planned deployment backends are listed in the root `README.md`.

## Canonical Deployment Generator

Docker Compose and Docker Swarm share:

`docker-compose/generate-docker-compose.sh`

When changing generated topology or behavior, modify the generator rather than
manually maintaining equivalent changes only in generated
`docker-compose.yml` files.

## Deployment Runtime Files

A normal deployment workspace contains:

```text
.env
config.yaml
docker-compose.yml
```

`.env` contains deployment environment variables and secrets.

`config.yaml` contains the CROWler runtime configuration.

`docker-compose.yml` is generated output.

## CROWler Runtime Configuration

CROWler Engine, API, and Events require `/app/config.yaml`.

A deployment must provide a deployment-level `config.yaml`.

Users may create it from either:

* `common/config/config.default`
* `common/config/config.default.remote`

Do not silently choose between local and remote configuration.

The generated Docker Compose or Swarm deployment must deliver the selected
configuration to:

`/app/config.yaml`

for:

* `crowler-engine-*`
* `crowler-api`
* `crowler-events`

Do not attach the CROWler configuration to DB, VDI, Jaeger, or Pushgateway
services.

Prefer Docker `configs` rather than host bind mounts for delivering
`config.yaml`. This keeps the same generated model usable with Docker Compose
and Docker Swarm.

## Environment and Credentials

Never invent credentials.

Do not overwrite an existing `.env` or `config.yaml` unless explicitly
requested.

Never expose credentials in:

* logs
* documentation
* commit messages
* generated examples
* responses

Use:

`common/env/env_template`

as the baseline environment template.

## Persistent Data

Treat Docker volumes and database storage as persistent user data.

Never remove persistent volumes, database data, configuration, or secrets as a
routine troubleshooting step.

## Validation

For Docker Compose:

```bash
docker compose config
```

For Docker Swarm:

```bash
docker stack config -c docker-compose.yml
```

Validation alone does not prove the deployment is healthy.

Also verify:

* expected CROWler images
* expected image versions
* Engine count
* VDI count
* Engine-to-VDI references
* networks
* persistent volumes
* CROWler config delivery
* exposed ports
* optional services
* resource limits
* environment resolution
* service health or Swarm task state

## Agent Skills

Task-specific AI instructions are under:

`.agents/skills/`

Currently available:

* `.agents/skills/deploy-docker-compose/`
* `.agents/skills/deploy-docker-swarm/`

Do not substitute one backend's workflow for another merely because they share
the same generator.
