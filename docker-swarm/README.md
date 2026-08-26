# Deploying The CROWler with Docker Swarm

Docker Swarm is the simplest multi-node step up from ordinary Docker Compose.
Use it when you already operate several Docker hosts and want CROWler services
to be scheduled across them without introducing Kubernetes or Nomad.

The deployment uses the same official CROWler images and the same root `.env`,
`config.yaml`, and `user/` content used by the other backends.

## What changes compared with Docker Compose?

Swarm adds:

* multi-node service scheduling;
* overlay networks;
* Docker Stack deployment;
* service-level resource limits and restart policies;
* versioned Docker Configs for `config.yaml` and user content.

Swarm has a dedicated generator because it must convert runtime configuration
and `user/*` files into immutable, content-hashed Docker Config objects. Use:

```text
./docker-swarm/generate-docker-compose.sh
```

The ordinary Compose generator is intentionally not the Swarm source of truth.

## Requirements

You need:

* Docker Engine with Swarm support;
* access to a Swarm manager;
* Bash;
* `sha256sum` or `shasum` for versioning Swarm configs;
* registry access from the Swarm nodes.

The examples assume the Swarm already exists. This repository does not
initialize or reconfigure your Swarm automatically.

## Before you start

Run every command from the repository root.

The normal deployment workspace is:

```text
thecrowler-deployment-support/
├── .env
├── config.yaml
├── docker-compose.yml
├── user/
│   ├── agents/
│   ├── plugins/
│   ├── rules/
│   └── support/
└── docker-swarm/
```

Do not `cd docker-swarm` before running the generator.

## 1. Create the environment file

```bash
cp common/env/env_template .env
```

Edit `.env` and set the credentials, image versions, and other values required
for your environment.

Do not commit the populated file.

## 2. Create `config.yaml`

For a complete local CROWler runtime configuration:

```bash
cp common/config/config.default config.yaml
```

For remote configuration bootstrap:

```bash
cp common/config/config.default.remote config.yaml
```

Choose one and edit it.

If you are unsure about the difference, see
[Configuration models](../docs/configuration.md).

## 3. Add optional deployment-specific CROWler content

Place custom files under:

```text
user/agents
user/plugins
user/rules
user/support
```

In Swarm mode these files are **not** mounted from node-local repository paths.
The generator converts each direct, non-hidden regular file into a content-
hashed Docker Config and mounts it at the stable runtime path under:

```text
/app/user/...
```

This means worker nodes do not need their own copy of the repository.

Docker Swarm Configs are limited to 500 KiB each. Use shared storage or an
artifact distribution mechanism for larger files.

Do not put secrets in `user/` because Docker Configs are not a secret store.

See [User deployment content](../user/README.md).

## 4. Generate a Swarm deployment

For example, generate two Engines, two VDIs, bundled PostgreSQL, and
Pushgateway:

```bash
./docker-swarm/generate-docker-compose.sh \
  -e=2 \
  -v=2 \
  --prom=yes \
  --pg=yes \
  --swarm=yes
```

This writes:

```text
docker-compose.yml
```

The file name is intentionally shared with the Compose workflow, but its
contents are generated specifically for Swarm.

Run the generator help for the full set of sizing and service options:

```bash
./docker-swarm/generate-docker-compose.sh --help
```

## 5. Validate the stack

Load the root environment so Docker can resolve variables while validating:

```bash
set -a
. ./.env
set +a
```

Then validate:

```bash
docker stack config -c docker-compose.yml
```

You can also run the repository-wide Swarm validator:

```bash
bash ./scripts/validate-deployment-support.sh swarm
```

Do this before every deployment change.

A Swarm-generated stack should contain:

* overlay networks;
* `deploy.resources` limits rather than Compose-only runtime limits;
* Swarm restart policies;
* versioned runtime configuration;
* versioned user-content configs;
* no node-local `./user/...` bind mounts.

## 6. Deploy the stack

From a Swarm manager:

```bash
docker stack deploy \
  -c docker-compose.yml \
  --resolve-image always \
  crowler
```

`crowler` is the stack name in these examples. You can use another name if your
operational conventions require it.

## 7. Inspect the deployment

List services:

```bash
docker stack services crowler
```

Inspect tasks and placement:

```bash
docker stack ps crowler --no-trunc
```

Inspect the versioned Docker Configs created for the stack:

```bash
docker config ls --filter label=com.docker.stack.namespace=crowler
```

For service logs, use the Swarm service name shown by `docker stack services`:

```bash
docker service logs -f SERVICE_NAME
```

## Updating `config.yaml` or user content

Docker Swarm Config objects are immutable.

The generator handles that constraint by hashing configuration content. When
`config.yaml` or a supported user file changes, regenerating the stack produces
a new versioned Docker Config while keeping the same target path inside the
container.

Update workflow:

```bash
./docker-swarm/generate-docker-compose.sh \
  -e=2 \
  -v=2 \
  --prom=yes \
  --pg=yes \
  --swarm=yes

set -a
. ./.env
set +a

docker stack config -c docker-compose.yml

docker stack deploy \
  -c docker-compose.yml \
  --resolve-image always \
  crowler
```

This lets Swarm roll services onto the new configuration rather than attempting
to mutate an existing Docker Config.

## Scaling

The generator expresses Engine and VDI counts in the generated stack.

For a persistent desired state, regenerate with the desired counts and redeploy,
for example:

```bash
./docker-swarm/generate-docker-compose.sh \
  -e=4 \
  -v=4 \
  --prom=yes \
  --pg=yes \
  --swarm=yes
```

Then validate and deploy again.

You can also use native `docker service scale` for temporary operational
changes, but regenerate the declared deployment if the new count should become
the long-lived desired state.

## Storage and PostgreSQL

Docker Swarm schedules tasks across nodes, but ordinary local Docker volumes
remain node-local.

Do not assume bundled PostgreSQL data automatically follows a database task to
another node.

For production deployments requiring node-independent database durability,
provide a storage solution appropriate for your Swarm environment or use an
external PostgreSQL service.

Do not remove persistent volumes as routine troubleshooting.

## Networks and ports

Swarm mode uses overlay networks for service communication.

Review the generated stack before exposing management or telemetry endpoints
outside trusted networks.

In particular, do not expose PostgreSQL, Selenium/VDI management, VNC, noVNC,
Chrome DevTools, Jaeger, or Pushgateway publicly unless your security design
explicitly requires it.

## Remove the stack

```bash
docker stack rm crowler
```

Removing the stack does not mean that persistent storage should be deleted.
Handle database volumes according to your retention and recovery policy.

## When should I choose something else?

Use [Docker Compose](../docker-compose/README.md) if everything belongs on one
host.

Consider [Nomad](../nomad/README.md) or [Helm/Kubernetes](../helm/README.md) if
you need the scheduling, service discovery, storage integrations, or ecosystem
of those platforms.

See [Choosing a deployment method](../docs/choosing-a-deployment.md) for a
broader comparison.
