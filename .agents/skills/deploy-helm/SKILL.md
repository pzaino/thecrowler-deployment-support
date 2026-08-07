---
name: deploy-helm
description: Install, configure, upgrade, validate, inspect, or troubleshoot The CROWler Helm chart in helm/thecrowler. Use for Helm values, CROWler image versions, replicas, bundled or external PostgreSQL, ConfigMap and Secret selection, storage, resources, scheduling, optional telemetry components, upgrades, and uninstall workflows.
compatibility: Requires thecrowler-deployment-support, Helm 3+, kubectl, and access to a Kubernetes cluster.
metadata:
  project: thecrowler
  repository: pzaino/thecrowler-deployment-support
  deployment-backend: helm
---

# Deploy The CROWler with Helm

## Sources of Truth

Inspect:

* `helm/README.md`
* `helm/thecrowler/Chart.yaml`
* `helm/thecrowler/values.yaml`
* `helm/thecrowler/values.schema.json`
* `helm/thecrowler/templates/`
* `kubernetes/README.md`
* `AGENTS.md`

## Architecture

Helm packages the same architecture as the raw Kubernetes manifests.

Do not create a second, divergent topology.

## Runtime Config

Production deployments should normally use an existing ConfigMap named
`crowler-config`.

Chart-managed config is supported with:

```text
config.create=true
config.content=<config.yaml contents>
```

Never invent a CROWler config.

## Secrets

Production deployments should normally use an existing Secret named
`crowler-secrets`.

Chart-managed secrets are supported for controlled environments, but never
place real credentials into committed values files.

## Validate

Run:

```text
helm lint
helm template
```

before install or upgrade.

## Upgrades

Use `helm upgrade --install` for idempotent deployment.

Preserve PostgreSQL PVCs across upgrades and uninstall/reinstall operations
unless persistent data deletion is explicitly intended.

## Safety

Do not expose internal VDI or database services publicly by default.

Do not use local image builds.

Do not silently enable bundled PostgreSQL when the user configured an external
database.
