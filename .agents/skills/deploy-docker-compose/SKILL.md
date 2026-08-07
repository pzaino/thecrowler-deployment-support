---

name: deploy-docker-compose
description: Deploy, configure, scale, validate, or troubleshoot The CROWler with Docker Compose using the official zfpsystems pre-built images. Use for CROWler Docker Compose installation, topology generation, Engine or VDI scaling, image version selection, environment configuration, Compose validation, startup, shutdown, logs, health checks, and deployment troubleshooting. Do not use for building CROWler images from source.
compatibility: Requires a checkout of thecrowler-deployment-support. Executing deployments requires Bash, Docker, and Docker Compose v2.
metadata:
  project: thecrowler
  repository: pzaino/thecrowler-deployment-support
  deployment-backend: docker-compose
  
---

# Deploy The CROWler with Docker Compose

Use this skill for Docker Compose deployment tasks in
`thecrowler-deployment-support`.

The repository consumes official pre-built CROWler images. It is not a
CROWler build repository.

## When to Use

Use this skill when the task involves:

* installing The CROWler with Docker Compose
* generating a CROWler Compose topology
* selecting CROWler or VDI image versions
* configuring a Compose deployment
* changing Engine or VDI instance counts
* enabling or disabling PostgreSQL, API, Events, Jaeger, or Pushgateway
* configuring CPU or memory limits
* validating a generated Compose file
* starting, stopping, inspecting, or troubleshooting a Compose deployment

## When Not to Use

Do not use this skill to:

* build CROWler binaries or Docker images from source
* modify the CROWler core implementation
* modify CROWler Dockerfiles
* develop CROWler plugins or rules
* deploy with Nomad, Kubernetes, or Helm

Source development belongs in:

`https://github.com/pzaino/thecrowler`

## Repository Sources of Truth

When working from a repository checkout, inspect the current versions of these
files before making deployment assumptions:

* `docker-compose/generate-docker-compose.sh`
* `docker-compose/README.md`
* `common/env/env_template`
* `common/config/config.default`
* `common/config/config.default.remote`
* `AGENTS.md`

The generator is the source of truth for generated Compose topology.

The Docker Compose README is the source of truth for the user-facing workflow.

Environment and configuration templates are the source of truth for supported
deployment variables.

If these files disagree, do not silently select one interpretation. Report the
conflict and use the generator behavior as the authoritative description of
what will actually be emitted.

See `references/configuration.md` for a condensed deployment reference.

## Official Image Contract

CROWler services must use the official pre-built images unless the user
explicitly requests another registry or image source:

* `zfpsystems/crowler-db`
* `zfpsystems/crowler-engine`
* `zfpsystems/crowler-vdi`
* `zfpsystems/crowler-api`
* `zfpsystems/crowler-events`

Never introduce local `build:` directives into deployment output.

Do not require the CROWler source repository merely to run a deployment.

Do not force `linux/amd64` by default. Official CROWler images are
multi-platform and Docker should select the appropriate supported platform.

## Version Contract

Use `CROWLER_VERSION` for:

* CROWler DB
* CROWler Engine
* CROWler API
* CROWler Events

Use `CROWLER_VDI_VERSION` independently for CROWler VDI.

For production deployments, prefer explicit image versions when the user has
not specifically requested a rolling `latest` deployment.

Never invent a release tag.

If the repository defaults disagree, report the discrepancy before modifying
deployment behavior.

## Required Deployment Inputs

Before generating a non-interactive deployment, establish:

1. Number of CROWler Engine instances.
2. Number of CROWler VDI instances.
3. Whether the bundled PostgreSQL database is required.
4. Whether Prometheus Pushgateway is required.
5. Whether API, Events, or Jaeger should be disabled.
6. Any requested CPU or memory limits.
7. CROWler image version.
8. CROWler VDI image version.

Use existing user-provided values when available.

Do not ask again for information that is already present in the task,
environment, or deployment configuration.

If optional values are unspecified, preserve documented generator defaults.

## Environment Handling

Never invent credentials.

Never expose credentials in logs, generated documentation, commit messages, or
the final response.

Do not overwrite an existing `.env` file unless explicitly requested.

When creating an environment file from a template, preserve user-owned values
and require real credentials to be supplied through an appropriate secret or
environment mechanism.

Before deployment, verify that the location referenced by Compose `env_file`
matches the actual environment file location.

Remember that Compose interpolation through `--env-file` and a service-level
`env_file:` entry serve different purposes. Do not assume that one
automatically satisfies the other.

## Generate the Deployment

Use:

`docker-compose/generate-docker-compose.sh`

as the canonical Compose generator.

For automated or agent-driven operation, prefer explicit arguments instead of
interactive prompts.

A typical non-interactive invocation is:

```bash
cd docker-compose
./generate-docker-compose.sh \
  -e=2 \
  -v=2 \
  --prom=yes \
  --pg=yes
```

Use only generator options supported by the current script.

Do not fabricate command-line options from documentation without checking the
current parser when modifying or troubleshooting generator behavior.

Generated `docker-compose.yml` is deployment output.

When changing how Compose files are generated, modify the generator rather
than manually maintaining equivalent changes only in generated output.

## Topology Checks

After generation, verify that:

* the requested number of Engine services exists
* the requested number of VDI services exists
* every referenced VDI service exists
* required networks exist
* required persistent volumes exist
* PostgreSQL is included or omitted as requested
* API, Events, Jaeger, and Pushgateway match the requested topology
* host ports do not collide
* all CROWler services use the expected image versions

If Engine and VDI counts differ, specifically verify Engine-to-VDI assignment.
Do not assume a one-to-one mapping unless the generated topology actually
provides one.

## Validate Before Starting

Run:

```bash
docker compose config
```

using the same Compose file and environment context that will be used to start
the deployment.

Validation must succeed before recommending startup.

Also verify that generated CROWler services contain no local build directives.

For example, inspect the rendered configuration and confirm that all CROWler
services resolve to the intended `zfpsystems` images.

## Pull and Start

When the user has asked to start the deployment:

```bash
docker compose pull
docker compose up -d
```

Use the required environment-file arguments if the deployment layout requires
them.

Then inspect:

```bash
docker compose ps
```

If health checks fail, inspect the affected service rather than repeatedly
restarting the entire stack.

## Troubleshooting

Start with the narrowest relevant evidence.

For a failing service:

```bash
docker compose logs SERVICE
```

For the overall deployment:

```bash
docker compose ps
docker compose config
```

Check, as applicable:

* image tag availability
* environment variables
* database connectivity
* container health checks
* Engine-to-VDI connectivity
* Docker networks
* port conflicts
* persistent volume state
* CPU and memory limits

Do not solve deployment failures by switching back to local image builds.

## Destructive Operations

Never run or recommend destructive cleanup as a routine troubleshooting step.

In particular, do not run:

```bash
docker compose down -v
```

unless the user explicitly requests deletion of persistent deployment data and
understands that volumes may contain the CROWler database.

Do not remove Docker volumes, database data, configuration, or user secrets
without explicit authorization.

## Completion Checks

Before considering a deployment task complete:

1. Confirm the generated Compose file validates.
2. Confirm all CROWler images are pull-based.
3. Confirm requested service counts and optional services.
4. Confirm image versions.
5. Confirm environment-file resolution.
6. Confirm persistent volumes are preserved.
7. If the deployment was started, report container and health status.
8. Report any unresolved configuration or topology inconsistency.

Do not claim that a deployment is healthy merely because Compose accepted the
YAML.
