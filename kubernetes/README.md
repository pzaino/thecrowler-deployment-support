# Deploying The CROWler with Kubernetes

This directory contains raw Kubernetes manifests for **The CROWler**.

The manifests are deliberately explicit and reviewable. For a configurable
packaged installation, use the Helm chart under `helm/thecrowler/`.

## Architecture

The default Kubernetes deployment uses:

* PostgreSQL as a single-replica StatefulSet with persistent storage
* API as a Deployment and ClusterIP Service
* Events as a Deployment and ClusterIP Service
* Engines as a Deployment
* VDIs as a Deployment behind a ClusterIP Service
* Jaeger as an optional Deployment and Service
* Prometheus Pushgateway as an optional Deployment and Service
* a ConfigMap containing the deployment `config.yaml`
* a Secret containing database credentials

The VDI Service uses `ClientIP` session affinity. This keeps requests from a
given Engine pod routed to the same VDI backend while the affinity is valid,
avoiding explicit Engine-to-VDI pod numbering.

For high concurrency, keep VDI replica capacity aligned with Engine workload.

## Requirements

* a Kubernetes cluster
* `kubectl`
* permission to create resources in a namespace
* access from cluster nodes to Docker Hub or your configured image registry

## 1. Prepare Deployment Inputs

From the repository root:

```bash
cp common/env/env_template .env
```

Choose one CROWler runtime configuration.

Local configuration:

```bash
cp common/config/config.default config.yaml
```

Remote bootstrap configuration:

```bash
cp common/config/config.default.remote config.yaml
```

Edit `.env` and `config.yaml`.

## 2. Create the Namespace

```bash
kubectl apply -f kubernetes/base/namespace.yaml
```

## 3. Create the CROWler ConfigMap

```bash
kubectl create configmap crowler-config   --namespace crowler   --from-file=config.yaml=./config.yaml   --dry-run=client   -o yaml | kubectl apply -f -
```

Engine, API, and Events mount this key at:

```text
/app/config.yaml
```

## 4. Create the Secret

Load the root environment file into the shell:

```bash
set -a
. ./.env
set +a
```

Create or update the Kubernetes Secret:

```bash
kubectl create secret generic crowler-secrets   --namespace crowler   --from-literal=DOCKER_POSTGRES_PASSWORD="$DOCKER_POSTGRES_PASSWORD"   --from-literal=DOCKER_CROWLER_DB_USER="$DOCKER_CROWLER_DB_USER"   --from-literal=DOCKER_CROWLER_DB_PASSWORD="$DOCKER_CROWLER_DB_PASSWORD"   --dry-run=client   -o yaml | kubectl apply -f -
```

Add additional secret keys when your CROWler plugins or integrations require
them.

## 5. Deploy PostgreSQL

```bash
kubectl apply -f kubernetes/base/database/
```

Skip this directory when using an external PostgreSQL database. When doing so,
update the Engine, API, and Events database host configuration or use Helm,
which exposes this setting directly.

## 6. Deploy VDI

```bash
kubectl apply -f kubernetes/base/vdi/
```

The VDI Service is internal-only by default.

For debugging a specific VDI pod, prefer `kubectl port-forward` rather than
publishing Selenium, VNC, noVNC, or Chrome DevTools cluster-wide.

## 7. Deploy Engine, API, and Events

```bash
kubectl apply -f kubernetes/base/engine/
kubectl apply -f kubernetes/base/api/
kubectl apply -f kubernetes/base/events/
```

## 8. Deploy Telemetry

Optional:

```bash
kubectl apply -f kubernetes/base/telemetry/
```

## Validate

Client-side validation:

```bash
kubectl apply --dry-run=client -f kubernetes/base/database/
kubectl apply --dry-run=client -f kubernetes/base/vdi/
kubectl apply --dry-run=client -f kubernetes/base/engine/
kubectl apply --dry-run=client -f kubernetes/base/api/
kubectl apply --dry-run=client -f kubernetes/base/events/
kubectl apply --dry-run=client -f kubernetes/base/telemetry/
```

Inspect the running deployment:

```bash
kubectl get pods -n crowler
kubectl get services -n crowler
kubectl get statefulsets -n crowler
kubectl get deployments -n crowler
```

## Scale Engine and VDI

Raw manifests default to two Engines and two VDIs.

Scale them with:

```bash
kubectl scale deployment/crowler-engine --replicas=4 -n crowler
kubectl scale deployment/crowler-vdi --replicas=4 -n crowler
```

For persistent desired configuration, edit the manifests or use Helm.

## Access the API

The API Service is ClusterIP by default.

For local access:

```bash
kubectl port-forward -n crowler service/crowler-api 8080:8080
```

## Access Jaeger

```bash
kubectl port-forward -n crowler service/crowler-jaeger 16686:16686
```

## Persistent Storage

The bundled PostgreSQL StatefulSet requests a `10Gi` PVC.

No `storageClassName` is specified, so the cluster's default StorageClass is
used.

API, Events, and Engine `/app/data` are `emptyDir` volumes in the raw
reference manifests so replica scaling does not depend on ReadWriteMany
storage. If your deployment requires persistent `/app/data`, use suitable
persistent storage or configure it through a site-specific manifest/Helm
extension.

## Security

The base manifests intentionally keep services internal.

Do not expose by default:

* PostgreSQL
* Selenium
* VDI management
* VNC
* noVNC
* Chrome DevTools
* Jaeger
* Pushgateway

Use an Ingress, Gateway, LoadBalancer, or port forwarding only for services
that need external access.

## Remove

Delete component resources:

```bash
kubectl delete -f kubernetes/base/telemetry/ --ignore-not-found
kubectl delete -f kubernetes/base/events/ --ignore-not-found
kubectl delete -f kubernetes/base/api/ --ignore-not-found
kubectl delete -f kubernetes/base/engine/ --ignore-not-found
kubectl delete -f kubernetes/base/vdi/ --ignore-not-found
kubectl delete -f kubernetes/base/database/ --ignore-not-found
```

Deleting the PostgreSQL StatefulSet does not automatically mean the PVC should
be deleted. Remove persistent database storage only when data deletion is
explicitly intended.

## Helm

For the configurable packaged deployment, see:

[../helm/README.md](../helm/README.md)
