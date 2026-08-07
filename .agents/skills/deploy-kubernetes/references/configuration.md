# Kubernetes Deployment Reference

## Namespace

Default:

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

Mounted into Engine, API, and Events at:

```text
/app/config.yaml
```

## Secret

Default Secret:

```text
crowler-secrets
```

Required keys:

```text
DOCKER_POSTGRES_PASSWORD
DOCKER_CROWLER_DB_USER
DOCKER_CROWLER_DB_PASSWORD
```

## VDI Routing

Service:

```text
crowler-vdi:4444
```

Session affinity:

```text
ClientIP
```

This gives each Engine pod stable backend affinity without explicit VDI pod
numbering.

## Persistence

Bundled PostgreSQL uses a StatefulSet and a `ReadWriteOnce` PVC.

Raw API, Events, and Engine `/app/data` use `emptyDir`.

## Images

```text
zfpsystems/crowler-db
zfpsystems/crowler-engine
zfpsystems/crowler-vdi
zfpsystems/crowler-api
zfpsystems/crowler-events
```

## Internal Services

```text
crowler-db:5432
crowler-vdi:4444
crowler-api:8080
crowler-events:8082
crowler-jaeger:16686
crowler-jaeger:4317
crowler-push-gateway:9091
```
