# Deploying The CROWler with Docker Compose

This directory contains the Docker Compose deployment tooling for **The CROWler**.

It is intended for users who want to run The CROWler using the official pre-built, multi-platform Docker images without cloning the main CROWler source repository, compiling Go binaries, or building Docker images locally.

The deployment generator can create a Docker Compose configuration with a configurable number of:

* CROWler Engine instances
* CROWler VDI instances
* CROWler API
* CROWler Events
* CROWler DB (PostgreSQL)
* CROWler Jaeger (Jaeger Open Telemetry)
* CROWler PushGateway (Prometheus Pushgateway)

The official CROWler container images are published on Docker Hub under the `zfpsystems` namespace.

## Official Docker Images

The Compose deployment uses the following CROWler images:

| Component | Docker image                |
| --------- | --------------------------- |
| Database  | `zfpsystems/crowler-db`     |
| Engine    | `zfpsystems/crowler-engine` |
| VDI       | `zfpsystems/crowler-vdi`    |
| API       | `zfpsystems/crowler-api`    |
| Events    | `zfpsystems/crowler-events` |

The deployment may also use third-party images for telemetry services such as:

* `jaegertracing/all-in-one`
* `prom/pushgateway`

The CROWler images are published as multi-platform images and can therefore run natively on supported AMD64 and ARM64 systems.

---

## Requirements

You need:

* Docker
* Docker Compose v2
* Bash
* Enough CPU and memory for the number of Engine and VDI instances you intend to run

Verify Docker Compose with:

```bash
docker compose version
```

No Go compiler, Docker Buildx setup, Selenium source tree, or CROWler source checkout is required.

---

## Quick Start

Clone the deployment repository:

```bash
git clone https://github.com/pzaino/thecrowler-deployment-support.git
cd thecrowler-deployment-support
```

Create your environment file from the supplied template:

```bash
cp common/env/env_template .env
```

Edit `.env` and configure at least the database passwords:

```bash
DOCKER_POSTGRES_PASSWORD='your-postgres-password'
DOCKER_CROWLER_DB_PASSWORD='your-crowler-password'
```

You can also select which CROWler image versions to deploy:

```bash
CROWLER_VERSION=latest
CROWLER_VDI_VERSION=4.28.1-20260807
```

Then enter this directory:

```bash
cd docker-compose
```

Run the generator:

```bash
./generate-docker-compose.sh
```

The script will ask for any deployment parameters that were not supplied on the command line and will generate:

```text
docker-compose.yml
```

Once generated, start the deployment with:

```bash
docker compose --env-file ../.env pull
docker compose --env-file ../.env up -d
```

Check the containers with:

```bash
docker compose --env-file ../.env ps
```

Follow their logs with:

```bash
docker compose --env-file ../.env logs -f
```

---

## Image Versions

Two environment variables control the CROWler images used by the generated deployment.

### CROWler Version

```bash
CROWLER_VERSION=latest
```

This version is used for:

```text
zfpsystems/crowler-db
zfpsystems/crowler-engine
zfpsystems/crowler-api
zfpsystems/crowler-events
```

For example:

```bash
CROWLER_VERSION=2.0.3
```

will cause the generated Compose deployment to use:

```text
zfpsystems/crowler-db:2.0.3
zfpsystems/crowler-engine:2.0.3
zfpsystems/crowler-api:2.0.3
zfpsystems/crowler-events:2.0.3
```

Using a specific release tag is recommended for reproducible production deployments.

Use `latest` when you intentionally want the latest published CROWler images.

### CROWler VDI Version

The VDI image has its own version because it includes the browser and Selenium environment and therefore follows a separate image versioning lifecycle.

For example:

```bash
CROWLER_VDI_VERSION=4.28.1-20260807
```

selects:

```text
zfpsystems/crowler-vdi:4.28.1-20260807
```

The VDI version can also be set to:

```bash
CROWLER_VDI_VERSION=latest
```

For production deployments, explicitly pinning the VDI version is recommended.

---

## Environment Configuration

The common environment template is located at:

```text
common/env/env_template
```

Copy it to `.env` before starting the Compose deployment:

```bash
cp common/env/env_template .env
```

Important variables include:

```bash
CROWLER_VERSION=latest

CROWLER_VDI_VERSION=4.28.1-20260807

DOCKER_DB_HOST='crowler-db'

DOCKER_POSTGRES_PASSWORD=''

DOCKER_CROWLER_DB_USER='crowler'

DOCKER_CROWLER_DB_PASSWORD=''
```

Never commit an environment file containing production passwords, tokens, or other credentials.

Additional environment variables can be added when required by CROWler configuration, plugins, rules, mail connectors, proxies, or other integrations.

---

## Generating a Deployment

The generator is:

```text
generate-docker-compose.sh
```

Run it interactively:

```bash
./generate-docker-compose.sh
```

or supply deployment settings as command-line arguments.

For example:

```bash
./generate-docker-compose.sh \
  -e=2 \
  -v=2 \
  --prom=yes \
  --pg=yes
```

This creates a deployment containing:

* 2 CROWler Engines
* 2 CROWler VDIs
* CROWler API
* CROWler Events
* CROWler DB
* Jaeger
* Prometheus Pushgateway

The resulting deployment uses published Docker images only. It does not build any CROWler component locally.

---

## Generator Options

Use:

```bash
./generate-docker-compose.sh --help
```

to display the available options.

The generator supports settings for:

| Option                        | Purpose                                                              |
| ----------------------------- | -------------------------------------------------------------------- |
| `-e=<number>`                 | Number of CROWler Engine instances                                   |
| `-v=<number>`                 | Number of CROWler VDI instances                                      |
| `--prometheus=<yes/no>`       | Enable or disable Prometheus Pushgateway                             |
| `--prom=<yes/no>`             | Short alias for Prometheus Pushgateway                               |
| `--postgres=<yes/no>`         | Enable or disable the bundled CROWler PostgreSQL database            |
| `--pg=<yes/no>`               | Short alias for PostgreSQL                                           |
| `--cpu_limit=<number>`        | Default CPU limit for services                                       |
| `--cpu_limit_engine=<number>` | CPU limit for Engine instances                                       |
| `--cpu_limit_vdi=<number>`    | CPU limit for VDI instances                                          |
| `--cpu_limit_mng=<number>`    | CPU limit for API and Events                                         |
| `--mem_limit_engine=<number>` | Engine memory allocation as a percentage of system memory            |
| `--mem_limit_vdi=<number>`    | VDI memory allocation as a percentage of system memory               |
| `--mem_limit_mng=<number>`    | API and Events memory allocation as a percentage of system memory    |
| `--mem_limit_tlm=<number>`    | Telemetry service memory allocation as a percentage of system memory |
| `--no_api`                    | Do not deploy CROWler API                                            |
| `--no_events`                 | Do not deploy CROWler Events                                         |
| `--no_jaeger`                 | Do not deploy Jaeger                                                 |
| `--swarm=<yes/no>`            | Generate resource/network settings suitable for Docker Swarm         |

If an Engine count, VDI count, Prometheus setting, or PostgreSQL setting is omitted, the generator asks for it interactively.

---

## Example: Minimal Deployment

A relatively small deployment can be generated with:

```bash
./generate-docker-compose.sh \
  -e=1 \
  -v=1 \
  --prom=no \
  --pg=yes \
  --no_events
```

This gives you:

```text
CROWler DB
    |
    +-- CROWler API
    |
    +-- CROWler Engine 1
            |
            +-- CROWler VDI 1
```

Jaeger remains enabled unless explicitly disabled with:

```bash
--no_jaeger
```

---

## Example: Standard Deployment

For a standard single-node deployment:

```bash
./generate-docker-compose.sh \
  -e=1 \
  -v=1 \
  --prom=yes \
  --pg=yes
```

This includes:

```text
CROWler DB
CROWler API
CROWler Events
CROWler Engine
CROWler VDI
Jaeger
Prometheus Pushgateway
```

---

## Example: Scaled Deployment

Multiple Engines and VDIs can be generated on the same Docker host.

For example:

```bash
./generate-docker-compose.sh \
  -e=4 \
  -v=4 \
  --prom=yes \
  --pg=yes
```

The generator creates services such as:

```text
crowler-engine-1
crowler-engine-2
crowler-engine-3
crowler-engine-4

crowler-vdi-1
crowler-vdi-2
crowler-vdi-3
crowler-vdi-4
```

Each VDI receives its own Docker network and host-side Selenium, VNC, noVNC, and Chrome DevTools ports.

All Engine instances are connected to the VDI networks so that the CROWler fleet can communicate with the browser infrastructure.

When scaling, make sure that the CROWler configuration matches the generated Engine and VDI topology.

---

## Resource Limits

The generator automatically detects the number of logical CPUs and the available system memory.

If explicit limits are not supplied, it derives defaults from the host.

CPU limits can be controlled globally:

```bash
--cpu_limit=4
```

or per service category:

```bash
--cpu_limit_engine=4
--cpu_limit_vdi=2
--cpu_limit_mng=1
```

Memory limits are specified as percentages of detected system memory.

For example:

```bash
--mem_limit_engine=50
--mem_limit_vdi=60
--mem_limit_mng=20
--mem_limit_tlm=20
```

The generator converts these values into Docker memory limits.

Be careful when running multiple instances. Resource limits apply to individual generated services, so the sum of all configured limits can exceed the resources physically available on the host.

VDI containers are typically the most memory-intensive part of a CROWler deployment.

---

## CROWler Configuration

Common configuration templates are available under:

```text
common/config/
```

The repository currently provides both local and remote configuration examples.

### Local Configuration

```text
common/config/config.default
```

This contains a full local CROWler configuration that can be adapted for a deployment.

It includes configuration for areas such as:

* database access
* crawler behavior
* Engine settings
* Selenium/VDI access
* networking
* APIs
* email crawling
* rules and plugins
* storage
* telemetry
* other CROWler runtime features

Do not store production credentials directly in the configuration file when environment variables or an external secrets system can be used instead.

### Remote Configuration

```text
common/config/config.default.remote
```

The remote configuration bootstrap can be used when CROWler instances should retrieve their actual fleet configuration from a central distribution endpoint.

It uses environment variables such as:

```text
CROWLER_DISTRIBUTION_HOST
CROWLER_DISTRIBUTION_PATH
CROWLER_DISTRIBUTION_PORT
CROWLER_DISTRIBUTION_REGION
CROWLER_DISTRIBUTION_TOKEN
CROWLER_DISTRIBUTION_SECRET
CROWLER_DISTRIBUTION_TIMEOUT
CROWLER_DISTRIBUTION_SSLMODE
```

Remote configuration is particularly useful for larger or distributed CROWler fleets where maintaining separate static configuration files on every host would be inconvenient.

---

## Database

When PostgreSQL support is enabled, the deployment uses:

```text
zfpsystems/crowler-db:${CROWLER_VERSION}
```

The CROWler DB image already contains the database initialization required by The CROWler.

No database initialization scripts from the main CROWler source repository are required.

The database data is stored in the Docker volume:

```text
db_data
```

The generated service exposes PostgreSQL on:

```text
5432
```

Database settings can be controlled through `.env`, including:

```bash
DOCKER_DB_HOST
DOCKER_POSTGRES_PASSWORD
DOCKER_CROWLER_DB_USER
DOCKER_CROWLER_DB_PASSWORD
```

If PostgreSQL is disabled:

```bash
--pg=no
```

you must configure The CROWler to connect to an external compatible database.

---

## CROWler VDI

Each CROWler VDI provides the browser execution environment used by CROWler Engines.

The VDI containers expose several services.

For the first VDI:

| Service                  |   Port |
| ------------------------ | -----: |
| Selenium                 | `4444` |
| VDI system management    | `4445` |
| VNC                      | `5900` |
| noVNC                    | `7900` |
| Chrome DevTools Protocol | `9222` |

Additional VDIs receive incremented host ports to avoid collisions.

For example, VDI 2 uses the next available host-side ports while retaining the expected internal container ports.

Each generated VDI also receives its own Docker network:

```text
crowler-vdi-1
crowler-vdi-2
...
```

---

## Jaeger

Unless disabled, Jaeger is deployed when at least one VDI is requested.

Disable it with:

```bash
--no_jaeger
```

The generated deployment exposes:

| Service            |    Port |
| ------------------ | ------: |
| Jaeger UI          | `16686` |
| OpenTelemetry gRPC |  `4317` |

The Jaeger UI can normally be reached at:

```text
http://localhost:16686
```

VDI tracing is configured to send telemetry to the Jaeger service by default.

---

## Prometheus Pushgateway

Prometheus Pushgateway can be enabled by answering `yes` during interactive generation or with:

```bash
--prom=yes
```

The generated deployment exposes Pushgateway on:

```text
9091
```

It can normally be reached at:

```text
http://localhost:9091
```

---

## Starting the Deployment

Pull all required images first:

```bash
docker compose --env-file ../.env pull
```

Then start the deployment:

```bash
docker compose --env-file ../.env up -d
```

Check its status:

```bash
docker compose --env-file ../.env ps
```

---

## Viewing Logs

All services:

```bash
docker compose --env-file ../.env logs -f
```

A specific Engine:

```bash
docker compose --env-file ../.env logs -f crowler-engine-1
```

A VDI:

```bash
docker compose --env-file ../.env logs -f crowler-vdi-1
```

The API:

```bash
docker compose --env-file ../.env logs -f crowler-api
```

The database:

```bash
docker compose --env-file ../.env logs -f crowler-db
```

---

## Stopping the Deployment

Stop and remove the containers while preserving persistent volumes:

```bash
docker compose --env-file ../.env down
```

To also remove Docker volumes:

```bash
docker compose --env-file ../.env down -v
```

**Warning:** removing volumes deletes persistent deployment data, including the local PostgreSQL database.

Do not use `-v` unless you intentionally want to remove that data.

---

## Updating The CROWler

To move to a different CROWler release, edit:

```bash
CROWLER_VERSION=<version>
```

in `.env`.

If necessary, update the VDI independently:

```bash
CROWLER_VDI_VERSION=<version>
```

Then pull the selected versions:

```bash
docker compose --env-file ../.env pull
```

and recreate the deployment:

```bash
docker compose --env-file ../.env up -d
```

For production installations, back up persistent data before performing significant upgrades.

---

## Multi-Platform Support

The official CROWler images are distributed as multi-platform images.

The Compose generator intentionally does not force:

```yaml
platform: linux/amd64
```

Docker therefore selects the appropriate published image for the host architecture.

This is important for systems including:

* AMD64/x86-64 Linux hosts
* ARM64 Linux hosts
* supported ARM64 development systems

Avoid manually adding a `platform` setting unless you have a specific reason to override Docker's platform selection.

---

## Docker Swarm

The generator currently supports:

```bash
--swarm=yes
```

When enabled, it generates Docker Swarm-style resource declarations and uses overlay networks instead of standard Compose bridge networks.

For more advanced distributed deployments, dedicated deployment definitions may be provided separately in this repository as the deployment support project evolves.

---

## Security Notes

For production deployments:

* Change all default passwords.
* Never commit `.env` files containing secrets.
* Prefer pinned CROWler image versions rather than `latest`.
* Restrict externally exposed container ports where appropriate.
* Protect PostgreSQL from untrusted networks.
* Protect Selenium, VNC, noVNC, Chrome DevTools, Jaeger, and Pushgateway endpoints from public access unless explicitly required.
* Use a secrets management solution for larger deployments.
* Back up persistent database data regularly.
* Review CROWler configuration and rule permissions before deployment.

---

## Troubleshooting

### Check generated Compose configuration

Before starting the deployment:

```bash
docker compose --env-file ../.env config
```

This validates and renders the Compose configuration.

### Check running containers

```bash
docker compose --env-file ../.env ps
```

### Check images

```bash
docker images | grep crowler
```

### Pull images again

```bash
docker compose --env-file ../.env pull
```

### Inspect a failing service

For example:

```bash
docker compose --env-file ../.env logs crowler-engine-1
```

or:

```bash
docker compose --env-file ../.env logs crowler-vdi-1
```

### Database connection failures

Verify:

```bash
DOCKER_DB_HOST
DOCKER_POSTGRES_PASSWORD
DOCKER_CROWLER_DB_USER
DOCKER_CROWLER_DB_PASSWORD
```

and inspect:

```bash
docker compose --env-file ../.env logs crowler-db
```

### VDI connection failures

Check that the requested VDI containers are running:

```bash
docker compose --env-file ../.env ps
```

and inspect the corresponding VDI logs:

```bash
docker compose --env-file ../.env logs crowler-vdi-1
```

---

## Regenerating the Compose File

`docker-compose.yml` is generated output.

If you want to change the topology, regenerate it instead of manually duplicating Engine or VDI services.

For example:

```bash
./generate-docker-compose.sh \
  -e=3 \
  -v=3 \
  --prom=yes \
  --pg=yes
```

Then validate the resulting configuration:

```bash
docker compose --env-file ../.env config
```

and apply it:

```bash
docker compose --env-file ../.env pull
docker compose --env-file ../.env up -d
```

---

## Building The CROWler from Source

This repository is intended for **deploying the official pre-built CROWler images**.

If you want to build, modify, or develop The CROWler itself, use the main project repository instead:

`pzaino/thecrowler`

The separation is intentional:

```text
thecrowler
    source code, development, builds and image publishing

thecrowler-deployment-support
    deployment of published CROWler artifacts
```

---

## Other Deployment Methods

Docker Compose is intended primarily for straightforward single-host and static deployments.

The `thecrowler-deployment-support` repository is designed to host additional deployment methods as they become available, including deployment technologies suitable for distributed and orchestrated CROWler fleets.

Refer to the repository root for the currently supported deployment methods.

---

## Project Links

The CROWler source repository:

`https://github.com/pzaino/thecrowler`

The CROWler deployment support repository:

`https://github.com/pzaino/thecrowler-deployment-support`

Official Docker images:

`https://hub.docker.com/u/zfpsystems`
