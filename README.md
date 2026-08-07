# The CROWler Deployment Support

Deployment tooling and documentation for running **The CROWler** using the official pre-built container images.

This repository is intended for users who want to deploy The CROWler without building the project from source.

It provides deployment-specific generators, configuration examples, documentation, and supporting files for running CROWler components on container platforms ranging from a single Docker host to larger orchestrated environments.

> If you want to build, modify, or contribute to The CROWler itself, use the main project repository:
>
> https://github.com/pzaino/thecrowler

---

## Table of Contents

* [What This Repository Is For](#what-this-repository-is-for)
* [Deployment Guides](#deployment-guides)
* [Quick Start](#quick-start)
* [Official CROWler Images](#official-crowler-images)
* [Repository Structure](#repository-structure)
* [Common Configuration](#common-configuration)
* [Versioning](#versioning)
* [Choosing a Deployment Method](#choosing-a-deployment-method)
* [Scaling The CROWler](#scaling-the-crowler)
* [Security](#security)
* [Building The CROWler from Source](#building-the-crowler-from-source)
* [Project Links](#project-links)

---

## What This Repository Is For

The main CROWler repository contains the source code, Docker build definitions, plugins, rules, schemas, services, and development tooling required to build The CROWler.

This repository has a different purpose.

**`thecrowler-deployment-support` is the consumer-side deployment repository.**

It is designed to let users deploy the official CROWler artifacts without requiring:

* a Go development environment
* Docker Buildx
* local CROWler builds
* Selenium source builds
* the CROWler source tree
* knowledge of the internal image build process

Instead, deployment definitions use the official pre-built CROWler images published on Docker Hub.

The repository will progressively provide deployment support for several container deployment and orchestration technologies.

---

## Deployment Guides

Each supported deployment technology has, or will have, its own directory and `README.md`.

| Deployment method | Status                                    | Documentation                                                                |
| ----------------- | ----------------------------------------- | ---------------------------------------------------------------------------- |
| Docker Compose    | **Available**                             | [Docker Compose deployment guide](docker-compose/README.md)                  |
| Docker Swarm      | Initial support through Compose generator | See [Docker Compose deployment guide](docker-compose/README.md#docker-swarm) |
| HashiCorp Nomad   | Planned                                   | `nomad/README.md`                                                            |
| Kubernetes        | Planned                                   | `kubernetes/README.md`                                                       |
| Helm              | Planned                                   | `helm/README.md`                                                             |

Additional deployment technologies may be added as the project evolves.

The intention is for each deployment directory to remain self-contained from a user perspective while sharing common CROWler configuration and conventions from this repository.

---

## Quick Start

The currently supported quick-start deployment uses Docker Compose.

### 1. Clone this repository

```bash
git clone https://github.com/pzaino/thecrowler-deployment-support.git
cd thecrowler-deployment-support
```

### 2. Create your environment file

```bash
cp common/env/env_template .env
```

Edit `.env` and configure the required values, particularly your database credentials.

For example:

```bash
DOCKER_POSTGRES_PASSWORD='your-postgres-password'
DOCKER_CROWLER_DB_USER='crowler'
DOCKER_CROWLER_DB_PASSWORD='your-crowler-password'
```

You can also select the CROWler versions to deploy:

```bash
CROWLER_VERSION=latest
CROWLER_VDI_VERSION=4.28.1-20260807
```

### 3. Generate the Docker Compose deployment

```bash
cd docker-compose
./generate-docker-compose.sh
```

The generator can be used interactively or configured through command-line arguments.

For example:

```bash
./generate-docker-compose.sh \
  -e=2 \
  -v=2 \
  --prom=yes \
  --pg=yes
```

### 4. Pull the images

```bash
docker compose --env-file ../.env pull
```

### 5. Start The CROWler

```bash
docker compose --env-file ../.env up -d
```

### 6. Check the deployment

```bash
docker compose --env-file ../.env ps
```

For complete instructions, configuration options, scaling examples, ports, telemetry, troubleshooting, and upgrade procedures, see:

**[Docker Compose Deployment Guide](docker-compose/README.md)**

---

## Official CROWler Images

Official CROWler container images are published under the `zfpsystems` namespace on Docker Hub.

| CROWler component | Docker image                |
| ----------------- | --------------------------- |
| Database          | `zfpsystems/crowler-db`     |
| Engine            | `zfpsystems/crowler-engine` |
| VDI               | `zfpsystems/crowler-vdi`    |
| API               | `zfpsystems/crowler-api`    |
| Events            | `zfpsystems/crowler-events` |

Docker Hub:

https://hub.docker.com/u/zfpsystems

The official images are distributed as multi-platform images so Docker can select the appropriate image for supported AMD64 and ARM64 environments.

Deployment definitions in this repository should use the published images rather than rebuilding CROWler components locally.

---

## Repository Structure

The repository is organized primarily by deployment technology.

The structure will evolve as additional deployment methods are added.

```text
thecrowler-deployment-support/
|
+-- README.md
|
+-- common/
|   |
|   +-- config/
|   |   +-- config.default
|   |   +-- config.default.remote
|   |
|   +-- env/
|       +-- env_template
|
+-- docker-compose/
|   +-- README.md
|   +-- generate-docker-compose.sh
|
+-- nomad/                         # planned
|   +-- README.md
|
+-- kubernetes/                    # planned
|   +-- README.md
|
+-- helm/                          # planned
    +-- README.md
```

Deployment-specific files should remain inside their corresponding directories.

Configuration and conventions that can be shared between deployment technologies belong under `common/`.

---

## Common Configuration

Reusable configuration assets are stored under:

```text
common/
```

These files are intended to provide a common baseline across the different deployment technologies supported by this repository.

### Environment Template

The common environment template is:

```text
common/env/env_template
```

Create your local `.env` from it:

```bash
cp common/env/env_template .env
```

The environment file contains deployment values such as:

```bash
CROWLER_VERSION
CROWLER_VDI_VERSION
DOCKER_DB_HOST
DOCKER_POSTGRES_PASSWORD
DOCKER_CROWLER_DB_USER
DOCKER_CROWLER_DB_PASSWORD
```

Additional variables can be added as required by CROWler configuration, plugins, rules, external services, mail connectors, proxies, telemetry, and other integrations.

Do not commit production credentials.

### Local CROWler Configuration

A local configuration template is available at:

```text
common/config/config.default
```

This is intended for deployments where CROWler instances receive their configuration locally.

### Remote CROWler Configuration

A remote bootstrap configuration is available at:

```text
common/config/config.default.remote
```

Remote configuration allows CROWler instances to retrieve their effective fleet configuration from a central distribution endpoint.

This mode is particularly useful as deployments grow beyond a single host because configuration can be managed centrally rather than maintained independently on every CROWler instance.

---

## Versioning

The main CROWler components share a CROWler image version selected through:

```bash
CROWLER_VERSION
```

For example:

```bash
CROWLER_VERSION=2.0.3
```

selects:

```text
zfpsystems/crowler-db:2.0.3
zfpsystems/crowler-engine:2.0.3
zfpsystems/crowler-api:2.0.3
zfpsystems/crowler-events:2.0.3
```

The VDI image has a separate version lifecycle because it also includes the browser and Selenium environment.

It is selected independently through:

```bash
CROWLER_VDI_VERSION
```

For example:

```bash
CROWLER_VDI_VERSION=4.28.1-20260807
```

selects:

```text
zfpsystems/crowler-vdi:4.28.1-20260807
```

`latest` can be used when desired:

```bash
CROWLER_VERSION=latest
CROWLER_VDI_VERSION=latest
```

For reproducible production deployments, explicit version tags are recommended.

---

## Choosing a Deployment Method

Different deployment technologies are appropriate for different CROWler environments.

### Docker Compose

Use Docker Compose when you want:

* a straightforward single-host installation
* development or testing environments
* small or medium static CROWler fleets
* explicit control over Engine and VDI instances
* minimal infrastructure requirements
* a quick way to get The CROWler running

See:

[Docker Compose Deployment Guide](docker-compose/README.md)

### Docker Swarm

Docker Swarm can be useful when you already operate Docker infrastructure and need multi-node scheduling without introducing a larger orchestration platform.

The current Compose generator contains initial Swarm support.

See:

[Docker Compose Deployment Guide: Docker Swarm](docker-compose/README.md#docker-swarm)

A dedicated Swarm deployment section may be introduced as the deployment tooling evolves.

### HashiCorp Nomad

Nomad support is planned for users who want:

* distributed CROWler fleets
* native task scheduling
* service discovery
* resource-aware placement
* integration with HashiCorp infrastructure
* declarative scaling of CROWler components

Planned documentation:

```text
nomad/README.md
```

### Kubernetes

Kubernetes support is planned for larger CROWler deployments requiring:

* horizontal scaling
* service discovery
* health management
* rolling deployments
* resource requests and limits
* persistent storage
* secret management
* scheduling and affinity controls
* integration with existing Kubernetes infrastructure

Planned documentation:

```text
kubernetes/README.md
```

### Helm

Helm support is planned as the primary packaged Kubernetes deployment interface.

It will allow CROWler components and replica counts to be configured through reusable values rather than maintaining large sets of Kubernetes manifests manually.

Planned documentation:

```text
helm/README.md
```

---

## Scaling The CROWler

The CROWler is composed of multiple services that can be deployed and scaled independently according to workload requirements.

Important components include:

```text
                    +----------------+
                    |   CROWler DB   |
                    +-------+--------+
                            |
             +--------------+--------------+
             |              |              |
             v              v              v
      +-------------+ +-------------+ +-------------+
      | CROWler API | |   Events    | |   Engines   |
      +-------------+ +-------------+ +------+------+
                                             |
                                  +----------+----------+
                                  |                     |
                                  v                     v
                           +-------------+       +-------------+
                           | CROWler VDI |       | CROWler VDI |
                           +-------------+       +-------------+
```

A deployment may therefore use different quantities of:

* API instances
* Events instances
* Engine instances
* VDI instances

depending on the workload and deployment platform.

Docker Compose currently provides static topology generation.

Future Nomad and Kubernetes support will make greater use of the native scheduling and scaling capabilities provided by those platforms.

Configuration must always remain consistent with the deployed CROWler fleet topology.

---

## Security

Deployment definitions are only one part of securing a CROWler installation.

For production environments:

* change all default passwords
* never commit `.env` files containing credentials
* prefer explicit image versions rather than uncontrolled upgrades
* restrict PostgreSQL access to trusted systems
* restrict Selenium and VDI management ports
* restrict VNC and noVNC access
* restrict Chrome DevTools endpoints
* protect Jaeger and telemetry interfaces
* use platform-native secret management where available
* back up persistent database data
* protect remote configuration credentials
* review CROWler plugins and rules before deploying them
* expose only the services that need to be reachable externally

Different deployment technologies will have additional security recommendations documented in their respective guides.

---

## Building The CROWler from Source

This repository does **not** build The CROWler.

That separation is intentional.

Use:

```text
pzaino/thecrowler
```

for:

* CROWler source code
* Go development
* plugins
* rules
* schemas
* Dockerfiles
* image builds
* CROWler development
* contributions to the core project

Use:

```text
pzaino/thecrowler-deployment-support
```

for:

* deployment generators
* deployment manifests
* orchestration definitions
* deployment examples
* common deployment configuration
* consuming the official pre-built images

Main CROWler repository:

https://github.com/pzaino/thecrowler

---

## Project Links

### The CROWler

Source code and main project:

https://github.com/pzaino/thecrowler

### Deployment Support

Pre-built image deployment tooling:

https://github.com/pzaino/thecrowler-deployment-support

### Official Docker Images

Docker Hub:

https://hub.docker.com/u/zfpsystems

### Project Overview

More information about The CROWler:

https://paolozaino.wordpress.com/portfolio/the-crowler/

---

## Deployment Documentation Index

As support is added, deployment documentation will be maintained in the corresponding directories.

| Platform       | Guide                                                                 |
| -------------- | --------------------------------------------------------------------- |
| Docker Compose | [docker-compose/README.md](docker-compose/README.md)                  |
| Docker Swarm   | [Docker Compose Swarm section](docker-compose/README.md#docker-swarm) |
| Nomad          | `nomad/README.md` *(planned)*                                         |
| Kubernetes     | `kubernetes/README.md` *(planned)*                                    |
| Helm           | `helm/README.md` *(planned)*                                          |

