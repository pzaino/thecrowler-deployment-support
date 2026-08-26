# Deploying The CROWler with Helm

The chart is located at:

```text
helm/thecrowler/
```

It packages the same architecture documented under `kubernetes/`.

## Requirements

* Kubernetes 1.27+
* Helm 4 recommended
* Helm 3 remains supported by this chart
* `kubectl`
* access to the official CROWler images

## Prepare Runtime Configuration

From the repository root:

```bash
cp common/env/env_template .env
```

Choose exactly one:

```bash
cp common/config/config.default config.yaml
```

or:

```bash
cp common/config/config.default.remote config.yaml
```

Edit both files.

Set:

```text
DOCKER_POSTGRES_PASSWORD
DOCKER_CROWLER_DB_USER
DOCKER_CROWLER_DB_PASSWORD
SEL_PASSWD
```

## Recommended Production Model

Use externally managed Kubernetes ConfigMaps and Secrets.

Create the namespace:

```bash
kubectl create namespace crowler --dry-run=client -o yaml | kubectl apply -f -
```

Create the runtime ConfigMap:

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
kubectl create secret generic crowler-secrets   -n crowler   --from-literal=DOCKER_POSTGRES_PASSWORD="$DOCKER_POSTGRES_PASSWORD"   --from-literal=DOCKER_CROWLER_DB_USER="$DOCKER_CROWLER_DB_USER"   --from-literal=DOCKER_CROWLER_DB_PASSWORD="$DOCKER_CROWLER_DB_PASSWORD"   --from-literal=SEL_PASSWD="$SEL_PASSWD"   --dry-run=client   -o yaml | kubectl apply -f -
```

Add any additional `.env` values required by plugins, rules, proxies, mail connectors, telemetry, or other integrations to the externally managed Secret as well.

Install:

```bash
helm upgrade --install crowler ./helm/thecrowler   --namespace crowler   --create-namespace
```

With release name `crowler`, resource names remain familiar:

```text
crowler-db
crowler-db-headless
crowler-api
crowler-events
crowler-engine
crowler-vdi
crowler-jaeger
crowler-push-gateway
```

A different Helm release name receives its own resource prefix, allowing
multiple CROWler releases in the same namespace.

## Updating an External ConfigMap

Kubernetes `subPath` mounts do not update inside existing pods.

After changing the externally managed ConfigMap, either restart:

```bash
kubectl rollout restart deployment/crowler-engine -n crowler
kubectl rollout restart deployment/crowler-api -n crowler
kubectl rollout restart deployment/crowler-events -n crowler
```

or force the same rollouts through Helm:

```bash
helm upgrade crowler ./helm/thecrowler   -n crowler   --set-string config.rolloutToken="$(date +%s)"
```

When `config.create=true`, the chart hashes `config.content` automatically and
rolls Engine/API/Events whenever the content changes.

## Updating an External Secret

When an externally managed Secret changes, restart its consumers or change:

```bash
helm upgrade crowler ./helm/thecrowler   -n crowler   --set-string secrets.rolloutToken="$(date +%s)"
```

When `secrets.create=true`, the chart hashes the chart-managed secret values
automatically and rolls affected workloads when they change.

## Chart-Managed ConfigMap

```bash
helm upgrade --install crowler ./helm/thecrowler   --namespace crowler   --create-namespace   --set config.create=true   --set-file config.content=./config.yaml
```

## Chart-Managed Secret

Create an uncommitted `values.private.yaml`:

```yaml
secrets:
  create: true
  existingSecret: ""
  data:
    postgresPassword: "replace-me"
    crowlerDbUser: "crowler"
    crowlerDbPassword: "replace-me"
    seleniumPassword: "replace-me"
```

Then:

```bash
helm upgrade --install crowler ./helm/thecrowler   --namespace crowler   --create-namespace   -f values.private.yaml
```

Existing Secrets are preferred for production.

## Versions

The chart defaults to:

```text
CROWler: 2.1.0
VDI:     4.28.1-20260819
```

Override them with:

```bash
helm upgrade --install crowler ./helm/thecrowler   -n crowler   --set global.crowlerVersion=2.1.0   --set global.vdiVersion=4.28.1-20260819
```

## Scaling

```bash
helm upgrade --install crowler ./helm/thecrowler   -n crowler   --set engine.replicas=4   --set vdi.replicas=4
```

VDI uses `ClientIP` session affinity.

## External PostgreSQL

```bash
helm upgrade --install crowler ./helm/thecrowler   -n crowler   --set database.enabled=false   --set database.host=postgres.example.internal
```

The configured Secret must contain the CROWler DB credentials.

## Validate

Run the shared repository validation when all validation dependencies are available:

```bash
bash ./scripts/validate-deployment-support.sh helm
```

The underlying chart checks are:

```bash
helm lint helm/thecrowler
helm template crowler helm/thecrowler --namespace crowler
```

CI additionally validates rendered resources against strict Kubernetes schemas with `kubeconform`.

Chart-managed config validation:

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

Do not delete PostgreSQL PVCs unless persistent data deletion is explicitly
intended.
