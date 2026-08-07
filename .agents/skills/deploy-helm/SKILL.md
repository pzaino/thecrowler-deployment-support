---
name: deploy-helm
description: Install, configure, upgrade, validate, inspect, or troubleshoot The CROWler Helm chart in helm/thecrowler. Use for Helm values, image versions, replicas, bundled or external PostgreSQL, ConfigMap and Secret selection, config/secret rollouts, storage, resources, scheduling, telemetry, multi-release deployments, upgrades, and uninstall workflows.
compatibility: Requires thecrowler-deployment-support, Helm 3 or 4, kubectl, and access to a Kubernetes cluster.
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

Helm packages the raw Kubernetes architecture.

Resources are release-prefixed and carry
`app.kubernetes.io/instance=<release>` so multiple CROWler releases can
coexist in one namespace.

## Runtime Config

Production should normally use an existing ConfigMap.

Chart-managed config:

```text
config.create=true
config.content=<config.yaml>
```

Chart-managed config changes automatically roll Engine/API/Events.

For externally managed ConfigMaps, use `config.rolloutToken` or explicitly
restart the three Deployments after changing the ConfigMap.

## Secrets

Baseline Secret keys:

```text
DOCKER_POSTGRES_PASSWORD
DOCKER_CROWLER_DB_USER
DOCKER_CROWLER_DB_PASSWORD
SEL_PASSWD
```

Chart-managed Secret changes automatically roll consumers.

For externally managed Secrets, use `secrets.rolloutToken` or restart
consumers.

Never commit real secret values.

## PostgreSQL

Bundled PostgreSQL uses:

* a release-scoped headless Service for StatefulSet identity
* a release-scoped ClusterIP Service for clients
* a StatefulSet with optional persistent PVC

When `database.enabled=false`, `database.host` is required.

## Validate

```text
helm lint helm/thecrowler
helm template <release> helm/thecrowler --namespace <namespace>
```

## Upgrades

Use `helm upgrade --install`.

Preserve PostgreSQL PVCs unless deletion is explicitly intended.
