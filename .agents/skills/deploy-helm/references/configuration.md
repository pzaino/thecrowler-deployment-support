# Helm Deployment Reference

Chart:

```text
helm/thecrowler/
```

## Image Versions

```text
global.crowlerVersion
global.vdiVersion
```

## Runtime Config

Existing ConfigMap:

```text
config.create=false
config.existingConfigMap=crowler-config
```

Chart-managed:

```text
config.create=true
config.content=<config.yaml>
```

## Secrets

Existing Secret:

```text
secrets.create=false
secrets.existingSecret=crowler-secrets
```

Chart-managed:

```text
secrets.create=true
```

## Replicas

```text
api.replicas
events.replicas
engine.replicas
vdi.replicas
```

## Database

Bundled:

```text
database.enabled=true
database.host=crowler-db
```

External:

```text
database.enabled=false
database.host=<external-host>
```

## Optional Components

```text
jaeger.enabled
pushgateway.enabled
```

## Storage

Bundled PostgreSQL:

```text
database.persistence.enabled
database.persistence.size
database.persistence.storageClass
```

## Scheduling

Each component supports:

```text
nodeSelector
tolerations
affinity
```
