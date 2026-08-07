# Deploying The CROWler with Docker Swarm

This directory documents how to deploy **The CROWler** with Docker Swarm using
the official pre-built CROWler images.

Docker Swarm is intended for deployments that need Docker-native multi-node
scheduling, service management, and overlay networking without introducing a
different orchestration platform.

The current Swarm deployment workflow reuses the canonical CROWler deployment
generator:

```text
docker-compose/generate-docker-compose.sh
```

with:

```text
--swarm=yes
```

## Official CROWler Images

The generated stack uses:

| Component | Docker image                |
| --------- | --------------------------- |
| Database  | `zfpsystems/crowler-db`     |
| Engine    | `zfpsystems/crowler-engine` |
| VDI       | `zfpsystems/crowler-vdi`    |
| API       | `zfpsystems/crowler-api`    |
| Events    | `zfpsystems/crowler-events` |

The official CROWler images are multi-platform.

Do not force `linux/amd64` unless your deployment specifically requires it.

---

## Requirements

You need:

* Docker Engine with Swarm support
* access to a Docker Swarm manager node
* Bash
* registry connectivity from nodes that may run CROWler tasks
* sufficient CPU and memory for the selected Engine and VDI topology

Check the current Swarm state with:

```bash
docker info
```

On a manager, list nodes with:

```bash
docker node ls
```

For a new Swarm, initialize it only when required:

```bash
docker swarm init
```

---

## Environment Setup

From the repository root:

```bash
cp common/env/env_template .env
```

Configure your deployment.

At minimum, review:

```bash
CROWLER_VERSION=latest
CROWLER_VDI_VERSION=4.28.1-20260807

DOCKER_DB_HOST='crowler-db'
DOCKER_POSTGRES_PASSWORD='your-postgres-password'
DOCKER_CROWLER_DB_USER='crowler'
DOCKER_CROWLER_DB_PASSWORD='your-crowler-password'
```

For reproducible production deployments, explicit image versions are
recommended.

Never commit production credentials.

---

## Environment Variables and Docker Swarm

Docker Swarm stack deployment does not perform `.env` interpolation in exactly
the same way as ordinary `docker compose`.

Before generating, validating, or deploying the stack, export the required
environment variables into the manager shell.

For example:

```bash
set -a
. ./.env
set +a
```

This provides variables used while rendering the stack definition.

Service-level:

```yaml
env_file:
  - .env
```

is a separate mechanism.

Make sure any generated `env_file` path resolves correctly from the location
where the stack definition is used.

---

## Generate the Swarm Stack

From the repository root:

```bash
./docker-compose/generate-docker-compose.sh \
  -e=2 \
  -v=2 \
  --prom=yes \
  --pg=yes \
  --swarm=yes
```

The generator produces:

```text
docker-compose.yml
```

The same generator supports Docker Compose and Docker Swarm, but
`--swarm=yes` changes the generated resource and networking model.

For automated deployments, specify the required arguments rather than relying
on interactive prompts.

---

## What Swarm Mode Changes

In Swarm mode, the generator uses:

* overlay networks instead of bridge networks
* `deploy.resources.limits` instead of Compose-only `cpus` and `mem_limit`
* no Compose `pull_policy` field

The remaining CROWler topology is still generated explicitly.

Services may include:

```text
crowler-db
crowler-api
crowler-events
crowler-engine-1
crowler-engine-2
...
crowler-vdi-1
crowler-vdi-2
...
crowler-jaeger
crowler-push-gateway
```

---

## Validate Before Deployment

Export the environment:

```bash
set -a
. ./.env
set +a
```

Then validate the generated stack:

```bash
docker stack config -c docker-compose.yml
```

Review the rendered output.

Check:

* official CROWler image names
* selected image versions
* Engine count
* VDI count
* Engine-to-VDI references
* overlay networks
* persistent volumes
* published ports
* resource limits
* PostgreSQL settings
* optional services

Docker Swarm stack deployment does not support every modern Docker Compose
feature.

Warnings about unsupported fields should be investigated rather than silently
ignored.

---

## Deploy the Stack

From a Swarm manager:

```bash
docker stack deploy \
  --compose-file docker-compose.yml \
  --resolve-image always \
  crowler
```

If worker nodes require registry credentials propagated from the manager,
configure registry authentication appropriately and use:

```bash
docker stack deploy \
  --compose-file docker-compose.yml \
  --resolve-image always \
  --with-registry-auth \
  crowler
```

when required.

---

## Inspect the Deployment

List the stack services:

```bash
docker stack services crowler
```

List stack tasks:

```bash
docker stack ps crowler
```

For additional detail:

```bash
docker stack ps crowler --no-trunc
```

Inspect a specific service:

```bash
docker service ps crowler_crowler-engine-1 --no-trunc
```

View its logs:

```bash
docker service logs crowler_crowler-engine-1
```

The actual service name includes the stack prefix.

---

## Updating The CROWler

Update your desired image versions or topology.

For example:

```bash
CROWLER_VERSION=2.0.3
CROWLER_VDI_VERSION=4.28.1-20260807
```

Regenerate the stack:

```bash
./docker-compose/generate-docker-compose.sh \
  -e=2 \
  -v=2 \
  --prom=yes \
  --pg=yes \
  --swarm=yes
```

Validate it:

```bash
docker stack config -c docker-compose.yml
```

Then deploy again using the same stack name:

```bash
docker stack deploy \
  -c docker-compose.yml \
  --resolve-image always \
  crowler
```

Swarm reconciles the running stack toward the new definition.

Back up persistent data before significant upgrades.

---

## Scaling

The current CROWler generator creates explicitly named Engine and VDI
services.

For example:

```text
crowler-engine-1
crowler-engine-2

crowler-vdi-1
crowler-vdi-2
```

To change the generated CROWler fleet topology, regenerate the stack with new
counts.

For example:

```bash
./docker-compose/generate-docker-compose.sh \
  -e=4 \
  -v=4 \
  --prom=yes \
  --pg=yes \
  --swarm=yes
```

Then validate and redeploy.

When Engine and VDI counts are different, verify that every Engine references
a VDI that actually exists.

---

## Persistent Storage

This is one of the most important differences between simple Compose and
multi-node Swarm.

The generated deployment may use named volumes such as:

```text
db_data
engine_data
api_data
events_data
```

The standard Docker local volume driver stores data on one Docker node.

If Swarm later schedules a stateful service on another node, that node does not
automatically receive the original local volume data.

Pay particular attention to PostgreSQL.

For production deployments, consider:

* constraining the DB service to a node with appropriate persistent storage
* using an external PostgreSQL database
* using storage infrastructure suitable for your multi-node environment

Do not delete database volumes as a routine troubleshooting step.

---

## Networking

Swarm mode uses Docker overlay networks.

The generated deployment contains networks such as:

```text
crowler-net
crowler-vdi-1
crowler-vdi-2
...
```

When the stack is deployed, Docker normally prefixes stack-owned resource names
with the stack name.

Overlay networking allows services scheduled on different Swarm nodes to
communicate through their declared networks.

---

## Published Ports

Depending on the generated topology, published ports may include:

| Service                  |                                  Port |
| ------------------------ | ------------------------------------: |
| CROWler API              |                                `8080` |
| CROWler Events           |                                `8082` |
| PostgreSQL               |                                `5432` |
| Selenium                 | `4444` and generated subsequent ports |
| VDI management           | `4445` and generated subsequent ports |
| VNC                      | `5900` and generated subsequent ports |
| noVNC                    | `7900` and generated subsequent ports |
| Chrome DevTools Protocol | `9222` and generated subsequent ports |
| Jaeger UI                |                               `16686` |
| OpenTelemetry gRPC       |                                `4317` |
| Prometheus Pushgateway   |                                `9091` |

Docker Swarm may expose published service ports through its routing mesh.

Review external exposure carefully in production environments.

---

## Troubleshooting

Start with:

```bash
docker stack services crowler
docker stack ps crowler --no-trunc
```

Then inspect the failing service:

```bash
docker service ps SERVICE --no-trunc
docker service logs SERVICE
```

Common causes of Swarm deployment failures include:

* unavailable image tags
* worker nodes unable to reach the registry
* registry authentication problems
* insufficient CPU or memory
* missing environment variables
* incorrect `env_file` paths
* port conflicts
* placement constraints
* node-local volume placement
* overlay-network connectivity problems
* Engine-to-VDI topology mismatches

Do not work around image-pull failures by rebuilding CROWler images in this
repository.

---

## Removing the Stack

Remove the deployed CROWler stack with:

```bash
docker stack rm crowler
```

This removes stack services and stack networks.

It does not imply that persistent database data should be deleted.

Never remove persistent volumes unless data deletion is explicitly intended.

---

## Security

For production Docker Swarm deployments:

* use explicit CROWler image versions
* protect manager-node access
* protect registry credentials
* never commit `.env` secrets
* restrict PostgreSQL access
* restrict Selenium access
* restrict VNC and noVNC
* restrict Chrome DevTools endpoints
* protect Jaeger and Pushgateway interfaces
* review Swarm routing-mesh exposure
* plan persistent database placement
* use appropriate secret-management mechanisms
* back up persistent CROWler data

---

## Docker Compose or Docker Swarm?

Use **Docker Compose** for straightforward single-host deployments.

Use **Docker Swarm** when you need:

* Docker-native multi-node scheduling
* overlay networking
* service reconciliation
* multi-node task placement
* Docker-native orchestration without Kubernetes or Nomad

Docker Compose documentation:

[../docker-compose/README.md](../docker-compose/README.md)

The main CROWler source repository remains separate:

https://github.com/pzaino/thecrowler
