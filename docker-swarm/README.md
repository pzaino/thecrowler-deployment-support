# Deploying The CROWler with Docker Compose

This directory contains the Docker Compose deployment tooling for **The
CROWler**.

## Repository-Root Execution Contract

Run every command from the repository root.

The normal deployment workspace is:

```text
.env
config.yaml
docker-compose.yml
user/
```

The generator intentionally fails when invoked from another directory.

## Quick Start

From the repository root:

```bash
cp common/env/env_template .env
```

Choose one:

```bash
cp common/config/config.default config.yaml
```

or:

```bash
cp common/config/config.default.remote config.yaml
```

Edit `.env` and `config.yaml`.

Add custom deployment content under:

```text
user/
├── agents/
├── plugins/
├── rules/
└── support/
```

Generate:

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

## User Content

In ordinary Docker Compose mode the generator uses read-only bind mounts:

```text
./user/agents   -> /app/user/agents
./user/plugins  -> /app/user/plugins
./user/rules    -> /app/user/rules
./user/support  -> /app/user/support
```

Because the generated `docker-compose.yml` is in the repository root, these
relative host paths resolve from the repository root.

Docker Swarm uses a different distribution mechanism. It does not use these
node-local bind mounts.

## Runtime Configuration

The deployment-level `config.yaml` is made available to Engine, API, and
Events at:

```text
/app/config.yaml
```

## Stop

```bash
docker compose down
```

Do not add `-v` unless persistent data deletion is explicitly intended.

## Docker Swarm

See:

[docker-swarm/README.md](../docker-swarm/README.md)
