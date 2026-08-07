# The CROWler Deployment Support

Deployment tooling and documentation for running **The CROWler** using the
official pre-built container images.

Source development belongs in:

https://github.com/pzaino/thecrowler

## Table of Contents

* [Deployment Guides](#deployment-guides)
* [Quick Start](#quick-start)
* [Deployment Files](#deployment-files)
* [Official Images](#official-images)
* [Configuration](#configuration)
* [Repository Structure](#repository-structure)
* [Project Links](#project-links)

## Deployment Guides

| Deployment method | Status | Documentation |
| --- | --- | --- |
| Docker Compose | **Available** | [Docker Compose guide](docker-compose/README.md) |
| Docker Swarm | **Available** | [Docker Swarm guide](docker-swarm/README.md) |
| HashiCorp Nomad | Planned | `nomad/README.md` |
| Kubernetes | Planned | `kubernetes/README.md` |
| Helm | Planned | `helm/README.md` |

## Quick Start

Clone the repository:

```bash
git clone https://github.com/pzaino/thecrowler-deployment-support.git
cd thecrowler-deployment-support
```

Create `.env`:

```bash
cp common/env/env_template .env
```

Create the CROWler runtime configuration.

For local configuration:

```bash
cp common/config/config.default config.yaml
```

Or for remote configuration bootstrap:

```bash
cp common/config/config.default.remote config.yaml
```

Edit `.env` and `config.yaml`.

Generate Docker Compose:

```bash
./docker-compose/generate-docker-compose.sh \
  -e=2 \
  -v=2 \
  --prom=yes \
  --pg=yes
```

Validate and start:

```bash
docker compose config
docker compose pull
docker compose up -d
```

For Swarm, use the same generator with:

```text
--swarm=yes
```

and follow [docker-swarm/README.md](docker-swarm/README.md).

## Deployment Files

A generated deployment is built around:

```text
.env
config.yaml
docker-compose.yml
```

`.env` contains deployment environment variables and secrets.

`config.yaml` contains CROWler runtime configuration.

`docker-compose.yml` is generated from the selected topology.

Engine, API, and Events receive `config.yaml` as `/app/config.yaml` through a
Docker config named `crowler_config`.

## Official Images

| Component | Docker image |
| --- | --- |
| Database | `zfpsystems/crowler-db` |
| Engine | `zfpsystems/crowler-engine` |
| VDI | `zfpsystems/crowler-vdi` |
| API | `zfpsystems/crowler-api` |
| Events | `zfpsystems/crowler-events` |

`CROWLER_VERSION` controls DB, Engine, API, and Events.

`CROWLER_VDI_VERSION` controls VDI independently.

## Configuration

Shared templates are under:

```text
common/
├── config/
│   ├── config.default
│   └── config.default.remote
└── env/
    └── env_template
```

Use `config.default` for a complete local CROWler configuration.

Use `config.default.remote` when the deployment should bootstrap and retrieve
its effective configuration from the configured remote distribution endpoint.

Do not commit production secrets.

## Repository Structure

```text
thecrowler-deployment-support/
├── AGENTS.md
├── README.md
├── .agents/
│   └── skills/
│       ├── deploy-docker-compose/
│       └── deploy-docker-swarm/
├── common/
│   ├── config/
│   └── env/
├── docker-compose/
│   ├── README.md
│   └── generate-docker-compose.sh
└── docker-swarm/
    └── README.md
```

## Project Links

Main CROWler repository:

https://github.com/pzaino/thecrowler

Deployment support:

https://github.com/pzaino/thecrowler-deployment-support

Docker Hub:

https://hub.docker.com/u/zfpsystems
