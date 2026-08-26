---
name: deploy-github-actions
description: Configure, validate, plan, apply, or troubleshoot The CROWler deployment automation provided by this repository through GitHub Actions. Use for protected GitHub Environments, deployment secrets, Helm/Kubernetes or Nomad workflow dispatch, self-hosted runners, image-version overrides, approval gates, and opt-in continuous deployment. Do not use to provision the underlying Kubernetes, Nomad, cloud network, or hyperscaler infrastructure.
compatibility: Requires thecrowler-deployment-support hosted on GitHub, GitHub Actions enabled, and an existing reachable Kubernetes or Nomad target. Private targets normally require an appropriately secured self-hosted runner.
metadata:
  project: thecrowler
  repository: pzaino/thecrowler-deployment-support
  deployment-backend: github-actions
---

# Deploy The CROWler with GitHub Actions

## Sources of Truth

Inspect before making deployment decisions:

* `.github/workflows/ci.yml`
* `.github/workflows/deploy.yml`
* `.github/workflows/continuous-deploy.yml`
* `docs/github-actions.md`
* `docs/production-deployment.md`
* `helm/README.md`
* `nomad/README.md`
* `AGENTS.md`

The GitHub Actions layer orchestrates existing Helm/Kubernetes or Nomad deployment definitions. It must not introduce a second CROWler workload topology.

## Deployment Boundary

The workflows deploy The CROWler onto an existing target.

Supported CD targets are:

```text
GitHub Actions -> Helm -> Kubernetes
GitHub Actions -> Nomad
```

Do not claim that these workflows create EKS, AKS, GKE, VPCs, subnets, Nomad clusters, or other underlying infrastructure.

## Required GitHub Environment

Use a GitHub Environment such as:

```text
production
```

For production, prefer required reviewers so deployment credentials are not released to the job until approval is granted.

Required Environment secrets for all deployment targets:

```text
CROWLER_CONFIG
CROWLER_ENV
```

`CROWLER_CONFIG` contains the complete deployment `config.yaml`.

`CROWLER_ENV` contains the complete deployment `.env` and must include non-empty values for:

```text
DOCKER_POSTGRES_PASSWORD
DOCKER_CROWLER_DB_USER
DOCKER_CROWLER_DB_PASSWORD
SEL_PASSWD
```

Do not commit these production values to the repository.

## Helm / Kubernetes

Additionally require:

```text
KUBECONFIG
```

The selected GitHub runner must be able to reach the Kubernetes API.

For a private cluster, use a self-hosted runner on a trusted network path rather than exposing the Kubernetes API merely to make CI/CD work.

## Nomad

Additionally require:

```text
NOMAD_ADDR
```

Optional depending on the cluster:

```text
NOMAD_TOKEN
NOMAD_NAMESPACE
```

The selected runner must be able to reach the Nomad API.

## Validate Before Deployment

Repository changes should first pass:

```text
Validate deployment support
```

For local equivalent checks, use:

```bash
./scripts/validate-deployment-support.sh all
```

Do not treat successful static validation as proof that a remote cluster is reachable or healthy.

## Plan

For a new environment, dispatch `Deploy The CROWler` with:

```text
operation = plan
backend   = helm | nomad
environment = <GitHub Environment>
```

Review the result before the first apply.

For Helm, planning uses a server-side Helm dry run against the selected cluster.

For Nomad, planning delegates to the repository's Nomad deployment workflow.

## Apply

After validation and an acceptable plan, dispatch:

```text
operation = apply
```

Do not bypass GitHub Environment approval controls for sensitive environments.

## Version Overrides

The workflow normally reads:

```text
CROWLER_VERSION
CROWLER_VDI_VERSION
```

from `CROWLER_ENV`.

Workflow-dispatch inputs may override them for one deployment.

Do not silently change image versions when the user did not request an upgrade.

## Continuous Deployment

Continuous deployment is intentionally disabled by default.

Enable it only when repository variable:

```text
CROWLER_AUTO_DEPLOY=true
```

is explicitly configured together with the required backend, environment, and runner variables documented in `docs/github-actions.md`.

A protected GitHub Environment may still require human approval even when continuous deployment is enabled.

Do not enable continuous deployment before manual plan/apply has been tested successfully for the target environment.

## Terraform Boundary

Terraform is validated by CI, but the provided GitHub deployment workflow does not automatically run Terraform apply.

Do not add state-changing Terraform automation on ephemeral runners unless the deployment has a persistent, encrypted, locked remote state backend and the user explicitly wants Terraform-based CD.

## Safety

Never:

* invent deployment credentials or GitHub secrets
* print secret contents into logs
* commit generated `.env`, `config.yaml`, kubeconfig, tokens, or private values
* weaken Environment approvals merely to make deployment pass
* expose a private control plane publicly as a shortcut
* claim cloud infrastructure provisioning that this repository does not implement
* enable continuous deployment without explicit intent
