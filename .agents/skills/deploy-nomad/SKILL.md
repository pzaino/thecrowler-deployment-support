---
name: deploy-nomad
description: Deploy, configure, validate, update, inspect, scale, or troubleshoot The CROWler with HashiCorp Nomad using the repository's nomad/crowler.nomad.hcl jobspec. Use for Nomad native service discovery, root config.yaml delivery, user agents/plugins/rules/support delivery, Nomad Variables, dynamic PostgreSQL host volumes, Docker task driver behavior, resource sizing, and Nomad job lifecycle. Do not use for Docker Compose, Swarm, Kubernetes, Helm, or source-image builds.
compatibility: Requires thecrowler-deployment-support, Nomad 1.10+, Docker-enabled Nomad clients, jq, and access to a Nomad server.
metadata:
  project: thecrowler
  repository: pzaino/thecrowler-deployment-support
  deployment-backend: nomad
---

# Deploy The CROWler with Nomad

## Execution Root

All commands run from the repository root.

Canonical inputs:

```text
.env
config.yaml
user/
nomad/crowler.nomad.hcl
```

Do not `cd nomad` before parsing, validating, planning, or submitting the job.
Nomad HCL `file()` and `fileset()` intentionally use repository-root-relative
paths.

## Sources of Truth

Inspect:

* `nomad/README.md`
* `nomad/crowler.nomad.hcl`
* `nomad/values.example.hcl`
* `nomad/config-runtime-contract.md`
* `nomad/volumes/crowler-db-data.hcl`
* `nomad/bootstrap-env.sh`
* `nomad/preflight.sh`
* `nomad/deploy.sh`
* `user/README.md`
* `AGENTS.md`

## Runtime Config

Engine, API, and Events must receive:

```text
/app/config.yaml
```

The jobspec reads root `config.yaml` at local HCL parse time and renders it into
each allocation.

Local VDI discovery requires the effective config to use:

```text
host: ${SELENIUM_HOST}
```

Do not silently deploy a literal localhost VDI configuration.

## User Content

Host:

```text
user/agents
user/plugins
user/rules
user/support
```

Runtime:

```text
/app/user/agents
/app/user/plugins
/app/user/rules
/app/user/support
```

Nomad must not require these directories on every client.

The jobspec uses local HCL `fileset()` / `file()` at submission time, renders
the content into allocation-local paths, and mounts those paths into Docker
tasks.

Use another delivery strategy for large/binary/frequently changing content.

## Secrets and Environment

The runtime Nomad Variable is:

```text
nomad/jobs/crowler/env
```

Use a read-only comparison before applying changes:

```bash
./nomad/deploy.sh env-check
```

Synchronize root `.env` only when a state-changing operation is intended:

```bash
./nomad/deploy.sh env-sync
```

`./nomad/deploy.sh plan` performs the same read-only drift check and must never
write the Nomad Variable.

Do not place production credentials in HCL variable files.

Nomad Variables are encrypted in Nomad state and accessible to the job through
its workload identity. Vault may be preferable for higher-security
deployments.

## Service Discovery

Default provider:

```text
provider = "nomad"
```

Services include DB, VDI, API, Events, Jaeger, and optional Pushgateway.

Engine-to-VDI selection uses `nomadService` rendezvous hashing with the
allocation ID.

Local VDI uses static port 4444 and `distinct_hosts`, so the eligible client
count must be at least `vdi_count`.

## PostgreSQL

Bundled PostgreSQL uses the dynamic host volume:

```text
crowler-db-data
```

`./nomad/deploy.sh run` idempotently ensures the volume exists before job
submission when `NOMAD_MANAGE_DATABASE_VOLUME=yes`, which is the default.

To ensure only the volume without submitting the job:

```bash
./nomad/deploy.sh volume-ensure
```

Use `volume-create` only for an explicit unconditional create operation.

Do not recreate or delete persistent database storage during ordinary
troubleshooting.

For production HA storage, prefer external PostgreSQL or an explicitly
designed shared/CSI storage backend.

## Validate / Plan / Run

```bash
./nomad/deploy.sh validate
./nomad/deploy.sh plan
./nomad/deploy.sh run
```

Semantics:

* `validate` is local/non-destructive validation;
* `plan` is read-only and must not synchronize environment values, create volumes, or submit a job;
* `run` may ensure bundled DB storage, synchronizes `.env`, and submits/updates the job.

Inspect:

```bash
./nomad/deploy.sh status
./nomad/deploy.sh allocations
```

## Docker Security

Do not enable privileged mode by default.

The Compose backend requests NET_ADMIN/NET_RAW, but Nomad Docker capabilities
are governed by client allowlists and Docker non-root limitations. Validate
network-scanning features in staging and add only the minimum capability policy
actually required.

## Safety

Never:

* run deployment tools from the wrong working directory
* overwrite `.env` or `config.yaml`
* put secrets in `nomad/values.hcl`
* delete persistent volumes routinely
* silently switch to locally built CROWler images
* claim a local dynamic host volume is highly available
* mutate Nomad Variables, volumes, or jobs during a plan operation
