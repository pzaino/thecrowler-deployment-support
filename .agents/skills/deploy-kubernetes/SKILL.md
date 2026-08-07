---
name: deploy-kubernetes
description: Deploy, configure, scale, validate, inspect, or troubleshoot The CROWler using the raw Kubernetes manifests in this repository. Use for Kubernetes namespaces, ConfigMaps, Secrets, StatefulSets, Deployments, Services, VDI routing, PostgreSQL persistence, resource limits, probes, scaling, and workload troubleshooting. Do not use when the user specifically wants the Helm chart.
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

Create Kubernetes ConfigMap `crowler-config` from the deployment-level
`config.yaml`.

Engine, API, and Events must mount:

`/app/config.yaml`

Do not mount that ConfigMap into DB, VDI, Jaeger, or Pushgateway.

## Secrets

Use Kubernetes Secret `crowler-secrets` for database credentials.

Never commit the generated Secret.

## Topology

The base architecture uses:

* PostgreSQL StatefulSet
* VDI Deployment + ClusterIP Service
* Engine Deployment
* API Deployment + Service
* Events Deployment + Service
* optional Jaeger and Pushgateway

The VDI Service uses `ClientIP` session affinity. Do not reintroduce Compose
ordinal-based Engine-to-VDI hostnames.

## Validate

Use client-side Kubernetes validation before applying.

Then inspect:

```text
Pods
Deployments
StatefulSets
Services
PVCs
ConfigMaps
Secrets
```

Do not claim health from YAML validation alone.

## Safety

Do not expose internal management services publicly by default.

Do not delete PostgreSQL PVCs as a routine troubleshooting step.

Do not replace official images with local builds.
