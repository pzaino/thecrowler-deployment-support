---
name: deploy-kubernetes
description: Deploy, configure, scale, validate, inspect, or troubleshoot The CROWler using the raw Kubernetes manifests in this repository. Use for namespaces, ConfigMaps, Secrets, StatefulSets, Deployments, Services, VDI routing, PostgreSQL persistence, resource limits, probes, scaling, config rollouts, and workload troubleshooting. Do not use when the user specifically wants the Helm chart.
compatibility: Requires thecrowler-deployment-support, kubectl, and access to a Kubernetes cluster.
metadata:
  project: thecrowler
  repository: pzaino/thecrowler-deployment-support
  deployment-backend: kubernetes
---

# Deploy The CROWler with Kubernetes

## Sources of Truth

Inspect:

* `kubernetes/README.md`
* `kubernetes/base/`
* `common/config/config.default`
* `common/config/config.default.remote`
* `common/env/env_template`
* `AGENTS.md`

## Runtime Inputs

Require:

```text
.env
config.yaml
```

Do not silently choose local versus remote `config.yaml`.

## Runtime Config

Create ConfigMap `crowler-config` from `config.yaml`.

Engine, API, and Events mount it at `/app/config.yaml`.

Because the file is mounted through `subPath`, a ConfigMap update requires
restarting Engine, API, and Events.

## Secrets

Use Secret `crowler-secrets`.

Required baseline keys:

```text
DOCKER_POSTGRES_PASSWORD
DOCKER_CROWLER_DB_USER
DOCKER_CROWLER_DB_PASSWORD
SEL_PASSWD
```

Restart consumers after changing Secret-backed environment variables.

## Topology

Use:

* PostgreSQL StatefulSet
* `crowler-db-headless` governing Service
* `crowler-db` client ClusterIP Service
* VDI Deployment + ClientIP-affinity Service
* Engine Deployment
* API Deployment + Service
* Events Deployment + Service
* optional Jaeger and Pushgateway

Raw VDI tracing is disabled until Jaeger is enabled.

## Validate

```bash
kubectl apply --dry-run=client -R -f kubernetes/base/
```

Then inspect Pods, Deployments, StatefulSets, Services, PVCs, ConfigMaps, and
Secrets.

## Safety

Do not expose internal management services publicly by default.

Do not delete PostgreSQL PVCs as routine troubleshooting.

Do not replace official images with local builds.
