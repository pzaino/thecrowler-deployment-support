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

Inspect:

* `.github/workflows/ci.yml`
* `.github/workflows/deploy.yml`
* `.github/workflows/continuous-deploy.yml`
* `.github/workflows/smoke.yml`
* `docs/github-actions.md`
* `docs/production-deployment.md`
* `helm/README.md`
* `nomad/README.md`
* `AGENTS.md`

The GitHub Actions layer orchestrates existing Helm/Kubernetes or Nomad deployment definitions. It must not introduce a second CROWler workload topology.

## Deployment Boundary

Supported CD targets are:

```text
GitHub Actions -> Helm -> Kubernetes
GitHub Actions -> Nomad
```

Do not claim that these workflows create EKS, AKS, GKE, VPCs, subnets, Nomad clusters, or other underlying infrastructure.

## Required GitHub Environment

Use a GitHub Environment such as `production`. For production, prefer required reviewers so deployment credentials are released only after approval.

Required Environment secrets for all targets:

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

Do not commit these production values.

## Helm / Kubernetes

Additionally require `KUBECONFIG`. The selected runner must be able to reach the Kubernetes API. For a private cluster, use a self-hosted runner on a trusted network path rather than exposing the API merely to make CI/CD work.

The workflow stores kubeconfig under the runner's temporary directory rather than replacing an operator's existing `~/.kube/config`.

Helm deployment mirrors the repository runtime contract:

* the complete deployment `.env` becomes the externally managed `crowler-secrets` Secret;
* `config.yaml` becomes `crowler-config`;
* `user/agents`, `user/plugins`, `user/rules`, and `user/support` become externally managed ConfigMaps and are enabled through the chart;
* apply uses atomic/wait semantics and a ten-minute timeout.

## Nomad

Additionally require `NOMAD_ADDR`. Depending on the cluster, also use `NOMAD_TOKEN` and `NOMAD_NAMESPACE`. The selected runner must be able to reach the Nomad API.

The workflow verifies the HashiCorp-published SHA256 checksum before installing the Nomad CLI.

## Validate Before Deployment

Repository changes should first pass `Validate deployment support`. The workflow exposes a single `Validation gate` job intended to be required by branch protection on `main`.

For the local equivalent:

```bash
bash ./scripts/validate-deployment-support.sh all
```

Do not treat successful structural validation as proof that a remote cluster is reachable or healthy.

## Plan and Apply

For a new environment, dispatch `Deploy The CROWler` with:

```text
operation = plan
backend = helm | nomad
environment = <GitHub Environment>
```

Plans may be run from development branches. `apply` is deliberately restricted to the `main` branch.

Review the plan, then dispatch `operation = apply` when appropriate. Do not bypass GitHub Environment approval controls for sensitive environments.

## Version Overrides

The workflow normally reads `CROWLER_VERSION` and `CROWLER_VDI_VERSION` from `CROWLER_ENV`. Workflow-dispatch inputs may override them for one deployment. Do not silently change image versions when the user did not request an upgrade.

## Continuous Deployment

Continuous deployment is disabled by default. Enable it only when `CROWLER_AUTO_DEPLOY=true` is explicitly configured with the required backend, environment, and runner variables documented in `docs/github-actions.md`.

A protected Environment may still require human approval even when continuous deployment is enabled. Do not enable continuous deployment before manual plan/apply has been tested successfully.

## Native Runtime Smoke Testing

Use `Smoke published CROWler deployment` when the user wants to verify published images before deployment. It runs on native AMD64 and ARM64 GitHub runners, verifies image architecture, starts a minimal Compose deployment, waits for core service health/running state, captures diagnostic logs, and removes all ephemeral smoke resources afterward.

The smoke workflow is not a production deployment and should remain on-demand because the VDI image is large and registry-dependent.

## Terraform Boundary

Terraform is validated by CI, but the provided deployment workflow does not automatically run Terraform apply. Do not add state-changing Terraform automation on ephemeral runners unless persistent, encrypted, locked remote state is configured and the user explicitly wants Terraform-based CD.

## Supply-Chain Rules

GitHub Actions used by the repository are pinned to immutable commit SHAs. Preserve SHA pinning when updating actions and annotate the corresponding release/tag for readability.

Downloaded deployment CLIs must be checksum-verified before installation.

## Safety

Never invent credentials, print secret contents into logs, commit generated credentials/configuration, weaken Environment or branch protections merely to make deployment pass, expose private control planes as a shortcut, claim cloud provisioning that is not implemented, or enable continuous deployment without explicit intent.
