# Docker Swarm Deployment Reference

## Canonical Files

| Purpose | Path |
| --- | --- |
| Shared generator | `docker-compose/generate-docker-compose.sh` |
| Swarm guide | `docker-swarm/README.md` |
| Environment template | `common/env/env_template` |
| Local config | `common/config/config.default` |
| Remote bootstrap | `common/config/config.default.remote` |
| Agent rules | `AGENTS.md` |

## Deployment Workspace

```text
.env
config.yaml
docker-compose.yml
```

## Generator

Enable Swarm mode with:

```text
--swarm=yes
```

Swarm mode uses:

```text
overlay networks
deploy.resources.limits
deploy.restart_policy
no container_name
no pull_policy
```

## Runtime Config

The generated stack declares:

```yaml
configs:
  crowler_config:
    file: "config.yaml"
```

and delivers it to Engine, API, and Events at:

```text
/app/config.yaml
```

Docker Swarm distributes this config to service tasks.

## Environment

Before `docker stack config` or `docker stack deploy`:

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
docker service ps SERVICE --no-trunc
docker service logs SERVICE
```

## Persistent Storage

Default local Docker volumes are node-local.

Pay particular attention to:

```text
db_data
```

Do not assume it follows PostgreSQL when Swarm reschedules the service.
