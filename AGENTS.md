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

Do not require a checkout of the main CROWler source repository merely to run
a deployment.

Official CROWler images are multi-platform. Do not force `linux/amd64` unless
there is an explicit platform requirement.

## Deployment Documentation

Read the README for the deployment backend being modified.

Currently supported:

* Docker Compose: `docker-compose/README.md`
* Docker Swarm: `docker-swarm/README.md`

Planned deployment backends are listed in the root `README.md`.

Do not assume a deployment backend is implemented merely because it is listed
as planned.

## Canonical Deployment Generator

Docker Compose and Docker Swarm currently share:

`docker-compose/generate-docker-compose.sh`

as their canonical deployment generator.

When changing generated topology or behavior, modify the generator rather than
manually maintaining equivalent changes only in generated `docker-compose.yml`
files.

Generated deployment files are output, not the primary implementation.

## Environment and Credentials

Never invent credentials.

Do not overwrite an existing `.env` file unless explicitly requested.

Never expose credentials in:

* logs
* documentation
* commit messages
* generated examples
* responses

Use:

`common/env/env_template`

as the baseline environment template.

Configuration templates are under:

`common/config/`

## Persistent Data

Treat Docker volumes and database storage as persistent user data.

Never remove persistent volumes, database data, configuration, or secrets as a
routine troubleshooting step.

In particular, do not use destructive cleanup commands merely to make a
deployment start successfully.

## Validation

Validate deployment output before declaring success.

For Docker Compose, use the equivalent of:

```bash
docker compose config
```

using the same environment context intended for deployment.

For Docker Swarm, use:

```bash
docker stack config -c docker-compose.yml
```

using the same environment exported for the eventual stack deployment.

Validation of YAML alone is not sufficient to claim that a deployment is
healthy.

Also verify, as appropriate:

* expected CROWler images
* expected image versions
* Engine count
* VDI count
* Engine-to-VDI references
* networks
* persistent volumes
* exposed ports
* optional services
* resource limits
* environment resolution
* service health or Swarm task state

## Agent Skills

Task-specific AI instructions are under:

`.agents/skills/`

Use the skill matching the deployment backend being worked on.

Currently available:

* `.agents/skills/deploy-docker-compose/`
* `.agents/skills/deploy-docker-swarm/`

Do not substitute one backend's workflow for another merely because they share
the same generator.
