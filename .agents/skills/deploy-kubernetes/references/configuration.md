# Kubernetes Deployment Reference

## Namespace

```text
crowler
```

## Runtime Configuration

ConfigMap:

```text
crowler-config
```

Key:

```text
config.yaml
```

Mounted with `subPath` at:

```text
/app/config.yaml
```

ConfigMap updates therefore require rollout restart of Engine, API, and Events.

## Secret

```text
crowler-secrets
```

Baseline keys:

```text
DOCKER_POSTGRES_PASSWORD
DOCKER_CROWLER_DB_USER
DOCKER_CROWLER_DB_PASSWORD
SEL_PASSWD
```

## PostgreSQL Services

Governing StatefulSet Service:

```text
crowler-db-headless
```

Application client endpoint:

```text
crowler-db:5432
```

## VDI

```text
crowler-vdi:4444
```

Session affinity:

```text
ClientIP
```

Raw VDI tracing defaults to disabled because Jaeger is optional.

## Persistence

PostgreSQL uses a `ReadWriteOnce` PVC.

Raw API, Events, and Engine `/app/data` use `emptyDir`.
