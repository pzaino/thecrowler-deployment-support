# Helm Deployment Reference

Chart:

```text
helm/thecrowler/
```

## Versions

```text
global.crowlerVersion
global.vdiVersion
```

## ConfigMap

External:

```text
config.create=false
config.existingConfigMap=crowler-config
config.rolloutToken=""
```

Chart-managed:

```text
config.create=true
config.content=<config.yaml>
```

## Secret

External:

```text
secrets.create=false
secrets.existingSecret=crowler-secrets
secrets.rolloutToken=""
```

Required keys:

```text
DOCKER_POSTGRES_PASSWORD
DOCKER_CROWLER_DB_USER
DOCKER_CROWLER_DB_PASSWORD
SEL_PASSWD
```

Chart-managed values:

```text
secrets.data.postgresPassword
secrets.data.crowlerDbUser
secrets.data.crowlerDbPassword
secrets.data.seleniumPassword
```

## Release Scoping

Helm resource names are derived from `.Release.Name`.

For release `crowler`:

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

Selectors include `app.kubernetes.io/instance`.

## Database

Bundled:

```text
database.enabled=true
```

External:

```text
database.enabled=false
database.host=<external-host>
```

## Replicas

```text
api.replicas
events.replicas
engine.replicas
vdi.replicas
```

## Optional Components

```text
jaeger.enabled
pushgateway.enabled
```

## Storage

```text
database.persistence.enabled
database.persistence.size
database.persistence.storageClass
```

## Scheduling

Each workload supports:

```text
nodeSelector
tolerations
affinity
```
