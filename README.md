# The CROWler Deployment Support

Deployment tooling and documentation for running **The CROWler** with official
pre-built container images.

Source development belongs in:

https://github.com/pzaino/thecrowler

## Deployment Guides

| Deployment method | Status | Documentation |
| --- | --- | --- |
| Docker Compose | **Available** | [Docker Compose](docker-compose/README.md) |
| Docker Swarm | **Available** | [Docker Swarm](docker-swarm/README.md) |
| Kubernetes | **Available** | [Kubernetes](kubernetes/README.md) |
| Helm | **Available** | [Helm](helm/README.md) |
| HashiCorp Nomad | Planned | `nomad/README.md` |

## Repository Root Is the Deployment Root

Run deployment commands from the repository root.

The normal workspace is:

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
├── common/
├── docker-compose/
├── docker-swarm/
├── kubernetes/
└── helm/
```

Create `.env`:

```bash
cp common/env/env_template .env
```

Create either:

```bash
cp common/config/config.default config.yaml
```

or:

```bash
cp common/config/config.default.remote config.yaml
```

## User Content

Deployment-specific CROWler content belongs under:

```text
user/agents
user/plugins
user/rules
user/support
```

The stable runtime contract is:

```text
/app/user/agents
/app/user/plugins
/app/user/rules
/app/user/support
```

Docker Compose uses read-only bind mounts.

Docker Swarm distributes direct user files through content-versioned Swarm
configs instead of node-local bind mounts.

See [user/README.md](user/README.md).

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
