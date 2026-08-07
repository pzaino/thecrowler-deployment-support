# Docker Compose Deployment Reference

## Canonical Files

| Purpose | Path |
| --- | --- |
| Generator | `docker-compose/generate-docker-compose.sh` |
| User guide | `docker-compose/README.md` |
| Environment template | `common/env/env_template` |
| Local config template | `common/config/config.default` |
| Remote config template | `common/config/config.default.remote` |
| Agent rules | `AGENTS.md` |

## Deployment Workspace

```text
.env
config.yaml
docker-compose.yml
```

## Config Selection

Local:

```bash
cp common/config/config.default config.yaml
```

Remote bootstrap:

```bash
cp common/config/config.default.remote config.yaml
```

Do not silently choose between them.

## Runtime Config Delivery

The generated deployment declares:

```yaml
configs:
  crowler_config:
    file: "config.yaml"
```

The following services receive it at `/app/config.yaml`:

* `crowler-api`
* `crowler-events`
* `crowler-engine-*`

## Official Images

| Component | Image | Version variable |
| --- | --- | --- |
| DB | `zfpsystems/crowler-db` | `CROWLER_VERSION` |
| Engine | `zfpsystems/crowler-engine` | `CROWLER_VERSION` |
| API | `zfpsystems/crowler-api` | `CROWLER_VERSION` |
| Events | `zfpsystems/crowler-events` | `CROWLER_VERSION` |
| VDI | `zfpsystems/crowler-vdi` | `CROWLER_VDI_VERSION` |

## Validation

```bash
docker compose config
```

Check:

```text
no CROWler build: directives
expected zfpsystems images
expected image tags
requested Engine count
requested VDI count
valid Engine-to-VDI mapping
crowler_config present
/app/config.yaml attached to Engine/API/Events
valid networks
valid volumes
no unintended port collisions
requested optional services
```
