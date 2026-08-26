# AI Agent Instructions

This repository deploys pre-built CROWler artifacts.

## Repository Root Is the Execution Root

All deployment commands and tools must be run from the repository root.

Canonical root-level deployment paths:

```text
.env
config.yaml
docker-compose.yml
user/
```

Relative deployment paths are intentionally repository-root relative.

## Repository Purpose

Do not build The CROWler from source in this repository.

Source development belongs in:

https://github.com/pzaino/thecrowler

## Official Images

Use:

* `zfpsystems/crowler-db`
* `zfpsystems/crowler-engine`
* `zfpsystems/crowler-vdi`
* `zfpsystems/crowler-api`
* `zfpsystems/crowler-events`

Do not introduce local image builds unless explicitly requested.

## Supported Backends

* Docker Compose: `docker-compose/README.md`
* Docker Swarm: `docker-swarm/README.md`
* Kubernetes: `kubernetes/README.md`
* Helm: `helm/README.md`
* HashiCorp Nomad: `nomad/README.md`
* Terraform: `terraform/README.md`
* GitHub Actions CI/CD: `docs/github-actions.md`

When the user has not selected a backend, consult `docs/choosing-a-deployment.md` before choosing one on their behalf.

GitHub Actions is an automation layer over Helm/Kubernetes and Nomad. It is not a separate workload topology and does not provision the underlying cloud or cluster infrastructure.

## Runtime Configuration

Engine, API, and Events require:

```text
/app/config.yaml
```

Create root `config.yaml` from exactly one of:

* `common/config/config.default`
* `common/config/config.default.remote`

Do not silently choose between them.

See `docs/configuration.md` for the difference between local and remote bootstrap configuration.

## User Deployment Content

Canonical host-side layout:

```text
user/
├── agents/
├── plugins/
├── rules/
└── support/
```

Canonical runtime layout:

```text
/app/user/agents
/app/user/plugins
/app/user/rules
/app/user/support
```

Never mount over built-in `/app/agents`, `/app/plugins`, `/app/rules`, or `/app/support`.

### Docker Compose

Use read-only repository-root bind mounts.

### Docker Swarm

Do not use node-local `./user/...` bind mounts. Use versioned Swarm configs for small direct user files.

### HashiCorp Nomad

Do not require `user/` directories on every Nomad client.

The Nomad CLI must be run from the repository root so HCL `file()` and `fileset()` can consume root `config.yaml` and `user/*` locally.

Use native Nomad service discovery by default.

Use Nomad Variables at:

```text
nomad/jobs/crowler/env
```

Bundled PostgreSQL uses a dynamic host volume. Do not describe local dynamic host volumes as highly available storage.

### Terraform

Terraform orchestrates existing deployment definitions.

Nomad Terraform must reuse:

```text
nomad/crowler.nomad.hcl
```

Helm Terraform must reuse:

```text
helm/thecrowler/
```

Run through:

```text
./terraform/run.sh <nomad|helm> ...
```

from the repository root.

Use provider write-only attributes for sensitive root `.env` payloads.

Do not duplicate CROWler workload topology as parallel Terraform resources.

Protect persistent database volumes from automatic Terraform destruction.

### GitHub Actions

GitHub Actions deployment must reuse the existing Helm/Kubernetes or Nomad paths.

Use protected GitHub Environments for production credentials and approvals.

For private control planes, prefer a secured self-hosted runner with network access rather than exposing a private Kubernetes or Nomad API publicly.

Do not enable continuous deployment without explicit intent.

Do not run state-changing Terraform from ephemeral CI runners unless persistent, encrypted, locked remote state has been explicitly configured.

## Credentials

Never invent credentials.

Never commit `.env`, production Secrets, private Helm values, Terraform tfvars/state, kubeconfig, Nomad tokens, or other credentials.

Do not put credentials inside `user/`.

## Validation

The canonical repository validation entry point is:

```bash
./scripts/validate-deployment-support.sh <target>
```

Targets are:

```text
static
compose
swarm
kubernetes
helm
nomad
terraform
skills
all
```

Prefer:

```bash
./scripts/validate-deployment-support.sh all
```

before declaring a deployment-support change valid.

The GitHub Actions CI workflow should use the same validation targets rather than maintain separate validation semantics.

Validation must remain non-destructive. It must not apply Kubernetes resources, submit Nomad jobs, initialize or mutate a Swarm, run Terraform apply, or delete persistent data.

Validation does not prove runtime health or target reachability.

Use the dedicated smoke workflow when image-level deployment smoke coverage is requested, and backend-specific plan/apply plus health checks for a live environment.

## Agent Skills

Task-specific instructions are under:

```text
.agents/skills/
```

Use `validate-deployment` for cross-backend validation and `deploy-github-actions` for CI/CD deployment automation.
