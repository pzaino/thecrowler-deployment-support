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

## Common Deployment Inputs

Create the environment file:

```bash
cp common/env/env_template .env
```

Create the CROWler runtime configuration from one configuration model.

Local configuration:

```bash
cp common/config/config.default config.yaml
```

Remote configuration bootstrap:

```bash
cp common/config/config.default.remote config.yaml
```

Edit the resulting `.env` and `config.yaml`.

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

## Kubernetes and Helm

Raw Kubernetes manifests live under:

```text
kubernetes/base/
```

They provide a transparent reference deployment.

The configurable Helm package lives under:

```text
helm/thecrowler/
```

Helm uses the same service architecture but exposes replicas, resources,
storage, service types, image versions, optional components, configuration,
and scheduling controls through `values.yaml`.

## Repository Structure

```text
thecrowler-deployment-support/
├── AGENTS.md
├── README.md
├── .agents/
│   └── skills/
│       ├── deploy-docker-compose/
│       ├── deploy-docker-swarm/
│       ├── deploy-kubernetes/
│       └── deploy-helm/
├── common/
│   ├── config/
│   └── env/
├── docker-compose/
├── docker-swarm/
├── kubernetes/
│   ├── README.md
│   └── base/
└── helm/
    ├── README.md
    └── thecrowler/
```

## Project Links

Main CROWler repository:

https://github.com/pzaino/thecrowler

Deployment support:

https://github.com/pzaino/thecrowler-deployment-support

Docker Hub:

https://hub.docker.com/u/zfpsystems
