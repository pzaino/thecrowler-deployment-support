# Deploying The CROWler with Helm

The Helm chart is located at:

```text
helm/thecrowler/
```

It packages the same architecture documented under `kubernetes/`.

## Requirements

* Kubernetes
* Helm 3+
* access to the official CROWler images

## Prepare Runtime Configuration

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

Edit both files.

## Recommended Production Model

Keep runtime configuration and secrets as existing Kubernetes objects.

Create the namespace:

```bash
kubectl create namespace crowler --dry-run=client -o yaml | kubectl apply -f -
```

Create the runtime configuration:

```bash
kubectl create configmap crowler-config   -n crowler   --from-file=config.yaml=./config.yaml   --dry-run=client   -o yaml | kubectl apply -f -
```

Load `.env`:

```bash
set -a
. ./.env
set +a
```

Create the Secret:

```bash
kubectl create secret generic crowler-secrets   -n crowler   --from-literal=DOCKER_POSTGRES_PASSWORD="$DOCKER_POSTGRES_PASSWORD"   --from-literal=DOCKER_CROWLER_DB_USER="$DOCKER_CROWLER_DB_USER"   --from-literal=DOCKER_CROWLER_DB_PASSWORD="$DOCKER_CROWLER_DB_PASSWORD"   --dry-run=client   -o yaml | kubectl apply -f -
```

Install:

```bash
helm upgrade --install crowler ./helm/thecrowler   --namespace crowler   --create-namespace
```

## Chart-Managed ConfigMap

Instead of creating `crowler-config` separately:

```bash
helm upgrade --install crowler ./helm/thecrowler   --namespace crowler   --create-namespace   --set config.create=true   --set-file config.content=./config.yaml
```

## Chart-Managed Secret

For non-production testing, the chart can create its Secret.

Create a private values file that is not committed:

```yaml
secrets:
  create: true
  existingSecret: ""
  data:
    postgresPassword: "replace-me"
    crowlerDbUser: "crowler"
    crowlerDbPassword: "replace-me"
```

Then:

```bash
helm upgrade --install crowler ./helm/thecrowler   --namespace crowler   --create-namespace   -f values.private.yaml
```

For production, existing Secrets are preferred.

## Image Versions

Override CROWler versions:

```bash
helm upgrade --install crowler ./helm/thecrowler   -n crowler   --set global.crowlerVersion=2.0.3   --set global.vdiVersion=4.28.1-20260807
```

## Scaling

```bash
helm upgrade --install crowler ./helm/thecrowler   -n crowler   --set engine.replicas=4   --set vdi.replicas=4
```

The VDI Service uses `ClientIP` session affinity for stable Selenium routing.

## External PostgreSQL

Disable the bundled database and set the database host:

```bash
helm upgrade --install crowler ./helm/thecrowler   -n crowler   --set database.enabled=false   --set database.host=postgres.example.internal
```

The Secret must still contain the CROWler DB username and password.

## Validate

```bash
helm lint helm/thecrowler
helm template crowler helm/thecrowler --namespace crowler
```

With chart-managed `config.yaml`:

```bash
helm template crowler helm/thecrowler   --namespace crowler   --set config.create=true   --set-file config.content=./config.yaml
```

## Upgrade

```bash
helm upgrade crowler ./helm/thecrowler -n crowler
```

## Uninstall

```bash
helm uninstall crowler -n crowler
```

Helm uninstall does not imply that persistent database PVCs should be deleted.
Review persistent storage before removing it.
