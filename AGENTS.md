# AI Agent Instructions

This repository deploys pre-built CROWler artifacts.

## Repository Purpose

Do not build The CROWler from source in this repository.

Source development belongs in:

https://github.com/pzaino/thecrowler

Use this repository for deployment tooling, deployment configuration,
documentation, and orchestration definitions that consume official CROWler
artifacts.

## Official Images

Use:

* `zfpsystems/crowler-db`
* `zfpsystems/crowler-engine`
* `zfpsystems/crowler-vdi`
* `zfpsystems/crowler-api`
* `zfpsystems/crowler-events`

unless the user explicitly requests another registry or image source.

Do not introduce local image builds into deployment definitions.

## Supported Deployment Backends

Currently supported:

* Docker Compose: `docker-compose/README.md`
* Docker Swarm: `docker-swarm/README.md`
* Kubernetes manifests: `kubernetes/README.md`
* Helm: `helm/README.md`

Planned backends are listed in the root `README.md`.

## CROWler Runtime Configuration

CROWler Engine, API, and Events require `/app/config.yaml`.

A deployment must provide a deployment-level `config.yaml`, normally created
from exactly one of:

* `common/config/config.default`
* `common/config/config.default.remote`

Do not silently choose between local and remote configuration.

Delivery mechanism by backend:

* Docker Compose: Docker config mounted at `/app/config.yaml`
* Docker Swarm: Swarm config mounted at `/app/config.yaml`
* Kubernetes: ConfigMap key `config.yaml` mounted at `/app/config.yaml`
* Helm: existing or chart-managed ConfigMap mounted at `/app/config.yaml`

Do not attach the CROWler runtime configuration to DB, VDI, Jaeger, or
Pushgateway.

## Credentials

Never invent credentials.

Never overwrite `.env`, `config.yaml`, Kubernetes Secrets, or private Helm
values unless explicitly requested.

Do not commit credentials.

## Kubernetes Invariants

Use Kubernetes-native primitives rather than recreating Compose behavior
literally.

The default Kubernetes topology uses:

* StatefulSet for bundled PostgreSQL
* Deployments for API, Events, Engine, VDI, Jaeger, and Pushgateway
* ClusterIP Services for internal service discovery
* a ConfigMap for CROWler `config.yaml`
* a Secret for sensitive deployment values
* a VDI Service with `ClientIP` session affinity for stable Selenium routing
* a headless Service governing the PostgreSQL StatefulSet
* an in-memory `emptyDir` mounted at `/dev/shm` for VDI

Do not expose PostgreSQL, Selenium, VNC, noVNC, Chrome DevTools, Jaeger, or
Pushgateway publicly by default.

## Helm Invariants

The Helm chart under `helm/thecrowler/` is the configurable packaging of the
same Kubernetes architecture.

Do not make Helm behavior diverge from the raw Kubernetes model without
documenting the difference.

Prefer existing Kubernetes Secrets and ConfigMaps in production.

Helm resources must be release-scoped so multiple releases can coexist in one namespace.

## Validation

Docker Compose:

```bash
docker compose config
```

Docker Swarm:

```bash
docker stack config -c docker-compose.yml
```

Kubernetes:

```bash
kubectl apply --dry-run=client -R -f kubernetes/base/
```

Validate component directories separately when the client cannot recursively
load a directory tree.

Helm:

```bash
helm lint helm/thecrowler
helm template crowler helm/thecrowler --namespace crowler
```

Validation does not prove runtime health.

## Agent Skills

Task-specific instructions are under `.agents/skills/`.

Available deployment skills:

* `deploy-docker-compose`
* `deploy-docker-swarm`
* `deploy-kubernetes`
* `deploy-helm`
