# Deploying The CROWler with Kubernetes

This directory contains raw Kubernetes manifests for **The CROWler**.

For a configurable packaged installation, use the Helm chart under
`helm/thecrowler/`.

## Architecture

The default Kubernetes deployment uses:

* PostgreSQL as a single-replica StatefulSet
* a headless PostgreSQL Service for StatefulSet network identity
* a normal ClusterIP PostgreSQL Service for CROWler clients
* API as a Deployment and ClusterIP Service
* Events as a Deployment and ClusterIP Service
* Engines as a Deployment
* VDIs as a Deployment behind a ClusterIP Service
* Jaeger as an optional Deployment and Service
* Prometheus Pushgateway as an optional Deployment and Service
* a ConfigMap containing `config.yaml`
* a Secret containing database and VDI credentials

The VDI Service uses `ClientIP` session affinity so requests from a given
Engine pod remain on the same VDI backend while the affinity is valid.

## Requirements

* a Kubernetes cluster
* `kubectl`
* permission to create resources in a namespace
* registry access from cluster nodes

## 1. Prepare Deployment Inputs

From the repository root:

```bash
cp common/env/env_template .env
```

Choose exactly one CROWler configuration model.

Local:

```bash
cp common/config/config.default config.yaml
```

Remote bootstrap:

```bash
cp common/config/config.default.remote config.yaml
```

Edit `.env` and `config.yaml`.

Set at least:

```text
DOCKER_POSTGRES_PASSWORD
DOCKER_CROWLER_DB_USER
DOCKER_CROWLER_DB_PASSWORD
SEL_PASSWD
```

## 2. Create the Namespace

```bash
kubectl apply -f kubernetes/base/namespace.yaml
```

## 3. Create or Update the Runtime ConfigMap

```bash
kubectl create configmap crowler-config   --namespace crowler   --from-file=config.yaml=./config.yaml   --dry-run=client   -o yaml | kubectl apply -f -
```

Engine, API, and Events mount this at:

```text
/app/config.yaml
```

### Important: ConfigMap Updates

The runtime config is mounted with Kubernetes `subPath` because the CROWler
images expect the file specifically at `/app/config.yaml`.

A ConfigMap change therefore does not update that file inside an already
running pod.

After updating `crowler-config`, restart the affected Deployments:

```bash
kubectl rollout restart deployment/crowler-engine -n crowler
kubectl rollout restart deployment/crowler-api -n crowler
kubectl rollout restart deployment/crowler-events -n crowler

kubectl rollout status deployment/crowler-engine -n crowler
kubectl rollout status deployment/crowler-api -n crowler
kubectl rollout status deployment/crowler-events -n crowler
```

## 4. Create or Update the Secret

Load `.env`:

```bash
set -a
. ./.env
set +a
```

Create the Secret:

```bash
kubectl create secret generic crowler-secrets   --namespace crowler   --from-literal=DOCKER_POSTGRES_PASSWORD="$DOCKER_POSTGRES_PASSWORD"   --from-literal=DOCKER_CROWLER_DB_USER="$DOCKER_CROWLER_DB_USER"   --from-literal=DOCKER_CROWLER_DB_PASSWORD="$DOCKER_CROWLER_DB_PASSWORD"   --from-literal=SEL_PASSWD="$SEL_PASSWD"   --dry-run=client   -o yaml | kubectl apply -f -
```

Environment variables sourced from a Secret are captured when a pod starts.
After changing `crowler-secrets`, restart the workloads that consume the
changed values.

Typical full restart:

```bash
kubectl rollout restart statefulset/crowler-db -n crowler
kubectl rollout restart deployment/crowler-engine -n crowler
kubectl rollout restart deployment/crowler-api -n crowler
kubectl rollout restart deployment/crowler-events -n crowler
kubectl rollout restart deployment/crowler-vdi -n crowler
```

## 5. Deploy PostgreSQL

Apply both Services and the StatefulSet:

```bash
kubectl apply -f kubernetes/base/database/
```

`crowler-db-headless` governs StatefulSet network identity.

`crowler-db` remains the normal ClusterIP endpoint used by CROWler services.

Skip bundled PostgreSQL when using an external database. Helm is recommended
for that configuration because the database host is directly configurable.

## 6. Deploy VDI

```bash
kubectl apply -f kubernetes/base/vdi/
```

The VDI Service is internal-only.

VDI tracing is disabled in the raw base because Jaeger is optional.

## 7. Deploy Engine, API, and Events

```bash
kubectl apply -f kubernetes/base/engine/
kubectl apply -f kubernetes/base/api/
kubectl apply -f kubernetes/base/events/
```

## 8. Optional Telemetry

Deploy Jaeger and Pushgateway:

```bash
kubectl apply -f kubernetes/base/telemetry/
```

Enable VDI tracing after Jaeger exists:

```bash
kubectl set env deployment/crowler-vdi   -n crowler   SE_ENABLE_TRACING=true   SE_OTEL_EXPORTER_ENDPOINT=http://crowler-jaeger:4317

kubectl rollout status deployment/crowler-vdi -n crowler
```

If Jaeger is removed, disable VDI tracing again:

```bash
kubectl set env deployment/crowler-vdi -n crowler SE_ENABLE_TRACING=false
```

## Validate

Validate the entire tree recursively:

```bash
kubectl apply --dry-run=client -R -f kubernetes/base/
```

Inspect:

```bash
kubectl get pods -n crowler
kubectl get services -n crowler
kubectl get deployments -n crowler
kubectl get statefulsets -n crowler
kubectl get pvc -n crowler
```

## Scale Engine and VDI

```bash
kubectl scale deployment/crowler-engine --replicas=4 -n crowler
kubectl scale deployment/crowler-vdi --replicas=4 -n crowler
```

For long-lived desired state, edit the manifests or use Helm.

## Access the API

```bash
kubectl port-forward -n crowler service/crowler-api 8080:8080
```

## Access Jaeger

```bash
kubectl port-forward -n crowler service/crowler-jaeger 16686:16686
```

## Persistence

Bundled PostgreSQL requests a `10Gi` `ReadWriteOnce` PVC.

The cluster default StorageClass is used unless you customize the manifest.

API, Events, and Engine `/app/data` use `emptyDir` in the raw reference
deployment.

## Security

Do not expose these publicly by default:

* PostgreSQL
* Selenium
* VDI management
* VNC
* noVNC
* Chrome DevTools
* Jaeger
* Pushgateway

Prefer `kubectl port-forward` for temporary administrative access.

## Remove

```bash
kubectl delete -f kubernetes/base/telemetry/ --ignore-not-found
kubectl delete -f kubernetes/base/events/ --ignore-not-found
kubectl delete -f kubernetes/base/api/ --ignore-not-found
kubectl delete -f kubernetes/base/engine/ --ignore-not-found
kubectl delete -f kubernetes/base/vdi/ --ignore-not-found
kubectl delete -f kubernetes/base/database/ --ignore-not-found
```

Do not delete PostgreSQL PVCs unless persistent data deletion is explicitly
intended.

## Helm

See:

[../helm/README.md](../helm/README.md)
