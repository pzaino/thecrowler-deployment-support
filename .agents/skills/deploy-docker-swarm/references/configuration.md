# Docker Swarm Deployment Reference

## Repository Root

All commands run from:

```text
thecrowler-deployment-support/
```

Root-level inputs/output:

```text
.env
config.yaml
docker-compose.yml
user/
```

## Generator

```text
docker-compose/generate-docker-compose.sh
```

Enable Swarm mode:

```text
--swarm=yes
```

## Runtime Config

Swarm configs are immutable.

The generator uses a content-hashed config key such as:

```text
crowler_config_012345abcdef
```

and mounts it at:

```text
/app/config.yaml
```

## User Content

Host:

```text
user/agents
user/plugins
user/rules
user/support
```

Container:

```text
/app/user/agents
/app/user/plugins
/app/user/rules
/app/user/support
```

Each direct user file becomes a content-hashed Swarm config.

Maximum size:

```text
500 KiB per file
```

Do not use Swarm configs for secrets.

## Environment

```bash
set -a
. ./.env
set +a
```

## Validate

```bash
docker stack config -c docker-compose.yml
```

## Deploy

```bash
docker stack deploy -c docker-compose.yml --resolve-image always crowler
```

## Inspect

```bash
docker stack services crowler
docker stack ps crowler --no-trunc
docker config ls --filter label=com.docker.stack.namespace=crowler
```

## Persistent Storage

Default local Docker volumes are node-local.

`db_data` requires explicit persistence planning in a multi-node Swarm.
