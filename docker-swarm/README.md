# Deploying The CROWler with Docker Swarm

Docker Swarm uses the same CROWler deployment generator as Docker Compose, with
Swarm mode enabled.

Run all commands from the repository root.

## Requirements

You need:

* Docker Engine with Swarm support
* access to a Swarm manager
* Bash
* registry connectivity from the nodes that may run CROWler tasks

## 1. Create `.env`

```bash
cp common/env/env_template .env
```

Edit `.env`.

## 2. Create `config.yaml`

For local configuration:

```bash
cp common/config/config.default config.yaml
```

For remote configuration bootstrap:

```bash
cp common/config/config.default.remote config.yaml
```

Edit the selected `config.yaml`.

The generated stack distributes this configuration to Engine, API, and Events
as `/app/config.yaml` using a Docker config.

This is intentionally not a host bind mount, so Swarm can distribute the
configuration to tasks scheduled on other nodes.

## 3. Export Environment Variables

`docker stack deploy` does not perform `.env` interpolation in the same way as
`docker compose`.

Export the environment on the manager:

```bash
set -a
. ./.env
set +a
```

The service-level `env_file` remains a separate mechanism.

## 4. Generate the Stack

```bash
./docker-compose/generate-docker-compose.sh \
  -e=2 \
  -v=2 \
  --prom=yes \
  --pg=yes \
  --swarm=yes
```

This creates:

```text
docker-compose.yml
```

## 5. Validate

```bash
docker stack config -c docker-compose.yml
```

Verify:

* official CROWler images
* expected image versions
* Engine and VDI counts
* Engine-to-VDI mapping
* overlay networks
* resource limits
* persistent volumes
* the `crowler_config` Docker config
* optional services
* published ports

## 6. Deploy

```bash
docker stack deploy \
  -c docker-compose.yml \
  --resolve-image always \
  crowler
```

If worker nodes require registry credentials propagated from the manager:

```bash
docker stack deploy \
  -c docker-compose.yml \
  --resolve-image always \
  --with-registry-auth \
  crowler
```

## 7. Inspect

```bash
docker stack services crowler
docker stack ps crowler --no-trunc
```

For a failing service:

```bash
docker service ps SERVICE --no-trunc
docker service logs SERVICE
```

## Swarm-Specific Generator Changes

With:

```text
--swarm=yes
```

the generator:

* uses overlay networks
* emits `deploy.resources.limits`
* emits a Swarm restart policy
* omits Compose `container_name`
* omits Compose `pull_policy`
* preserves the same official CROWler images
* preserves Docker `configs` delivery of `config.yaml`

## CROWler Configuration

The stack contains:

```yaml
configs:
  crowler_config:
    file: "config.yaml"
```

Engine, API, and Events receive:

```yaml
configs:
  - source: crowler_config
    target: /app/config.yaml
```

Swarm creates and distributes the configuration through the stack.

Do not replace this with a node-local bind mount unless the deployment
explicitly requires that model.

## Persistent Storage

Default Docker local volumes are node-local.

Pay particular attention to PostgreSQL. A local `db_data` volume does not
automatically move if Swarm reschedules PostgreSQL to another node.

For production deployments, consider:

* constraining PostgreSQL to an appropriate persistent node
* using external PostgreSQL
* using suitable shared or distributed storage

## Remove the Stack

```bash
docker stack rm crowler
```

This does not mean persistent volumes should be deleted.

## Docker Compose

For single-host Compose deployment use:

[docker-compose/README.md](../docker-compose/README.md)
