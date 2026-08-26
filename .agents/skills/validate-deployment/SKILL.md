---
name: validate-deployment
description: Validate The CROWler deployment-support repository or a prepared deployment across Docker Compose, Docker Swarm, raw Kubernetes, Helm, HashiCorp Nomad, Terraform, GitHub Actions support files, and AI deployment skills. Use before deployment changes, pull requests, releases, or when diagnosing whether a deployment definition is structurally valid. Validation does not prove live runtime health.
compatibility: Requires thecrowler-deployment-support repository and the command-line tools needed by the selected validation target. Full validation requires Bash, ShellCheck, Docker with Compose v2, kubectl, Helm, Nomad 1.10+, Terraform 1.15+, and jq.
metadata:
  project: thecrowler
  repository: pzaino/thecrowler-deployment-support
  deployment-backend: validation
---

# Validate CROWler Deployment Support

## Source of Truth

Use the repository validator:

```bash
bash ./scripts/validate-deployment-support.sh <target>
```

Do not duplicate its validation rules in ad-hoc agent commands unless investigating a failure.

Available targets:

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

## Full Validation

Before declaring a repository change deployment-safe, prefer:

```bash
bash ./scripts/validate-deployment-support.sh all
```

This is a structural and offline validation pass. It is not a substitute for testing against a live destination.

## Static Validation

`static` checks required repository paths, all shell scripts through ShellCheck, and AI skill structure and metadata.

Use `skills` when only the AI deployment instructions need validation.

## Docker Compose

`compose` generates a small single-host deployment and parses it with Docker Compose. It validates generated configuration rather than starting production workloads.

## Docker Swarm

`swarm` generates Swarm-compatible output and validates it with `docker stack config`. It also checks that Swarm user content does not fall back to node-local `./user/...` bind mounts and that runtime configuration is versioned.

This does not create or mutate a Docker Swarm.

## Kubernetes

`kubernetes` performs client-side validation of the raw manifest tree. It does not connect to or modify a Kubernetes cluster.

## Helm

`helm` runs chart linting and rendering. It does not install a Helm release.

## Nomad

`nomad` uses the repository's own Nomad validation path, including preflight, formatting, and `nomad job validate`. It does not submit the job.

## Terraform

`terraform` validates both supported Terraform roots:

```text
terraform/helm
terraform/nomad
```

It checks formatting, initializes providers with the state backend disabled, and runs the repository Terraform validation wrapper. It must not run `terraform apply` during repository validation.

## CI Relationship

The GitHub Actions workflow `Validate deployment support` should call the same repository validator targets used locally.

When CI fails, inspect the failed target rather than bypassing or weakening the validation rule.

## Runtime Smoke Tests

Static validation cannot prove that published images start correctly or that a real cluster is reachable.

Use the `Smoke published CROWler deployment` GitHub Actions workflow when image-level deployment smoke coverage is requested. It verifies native AMD64 and ARM64 image selection and Compose container creation without starting a production deployment.

For production targets, use backend-specific plan/apply and health checks after structural validation succeeds.

## Safety

Never turn validation into an implicit deployment, delete persistent data, initialize or mutate a Swarm, apply Kubernetes resources, submit a Nomad job, run Terraform apply, or suppress a failing validation without understanding why it fails.
