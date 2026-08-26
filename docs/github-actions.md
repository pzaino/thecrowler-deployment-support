# GitHub Actions deployment automation

This repository includes GitHub Actions workflows for validating deployment definitions, smoke-testing published images, and deploying The CROWler.

## Workflows

### `Validate deployment support`

Runs on pull requests and pushes to `main`.

It uses the same repository validator available to humans and AI agents:

```bash
bash ./scripts/validate-deployment-support.sh <target>
```

CI validates:

* repository structure and all shell scripts with ShellCheck;
* deployment image-version consistency;
* AI deployment skill structure and metadata;
* generated Docker Compose output;
* generated Docker Swarm output using the dedicated Swarm generator, including immutable config and user-content rules;
* raw Kubernetes manifests with strict `kubeconform` schemas;
* the Helm chart with linting, rendering, and strict Kubernetes schema validation;
* the Nomad jobspec with preflight, formatting, and `nomad job validate`;
* Terraform formatting and validation for both `terraform/helm` and `terraform/nomad`.

All validation jobs feed a single status named:

```text
Validation gate
```

This is the status that should be required by branch protection or a repository ruleset for `main`.

These checks are non-destructive. They do not connect to a production target and do not deploy anything.

## Protect `main`

CI can expose a required status, but repository protection is a GitHub repository setting rather than something a workflow should silently change itself.

For production-quality operation, protect `main` with a branch rule or repository ruleset that:

* requires pull requests before merging;
* requires the `Validation gate` status check;
* requires the branch to be up to date before merging when that fits your workflow;
* prevents force pushes and branch deletion;
* optionally requires review approvals.

This turns deployment validation from an advisory check into an enforced merge gate.

### `Smoke published CROWler deployment`

Runs on demand through `workflow_dispatch`.

The smoke workflow uses native GitHub-hosted AMD64 and ARM64 runners. For the selected CROWler and VDI image tags it:

1. generates and validates a minimal Docker Compose deployment;
2. pulls the official DB, Engine, API, Events, and VDI images;
3. verifies native image selection resolves to the expected `linux/amd64` or `linux/arm64` architecture;
4. starts the deployment with `docker compose up -d`;
5. waits for DB, API, Events, and Engine health checks and verifies that VDI remains running;
6. prints final status and diagnostic logs;
7. removes the ephemeral containers, networks, volumes, and generated runtime files.

Use this before an important deployment or release when you want runtime assurance that the published multi-architecture artifacts can actually start together using the generated deployment topology.

It intentionally does not run on every pull request because the VDI image is large and registry-dependent.

### `Deploy The CROWler`

Runs through `workflow_dispatch` and supports:

* Helm/Kubernetes;
* HashiCorp Nomad;
* `plan`;
* `apply`;
* GitHub-hosted or self-hosted runners;
* CROWler and VDI image-version overrides.

Plans may be run from a development branch. `apply` is restricted to `main`.

The workflow uses the repository's existing deployment definitions rather than creating a second topology.

Helm uses:

```text
helm/thecrowler/
```

Nomad uses:

```text
nomad/deploy.sh
nomad/crowler.nomad.hcl
```

Terraform remains validated by CI but is not automatically applied. Production CI/CD should not run state-changing Terraform operations from an ephemeral runner until an encrypted, locked, persistent remote state backend has been configured.

## GitHub Environment setup

Create a GitHub Environment such as:

```text
production
```

For production, configure required reviewers so `apply` runs require approval.

The deployment workflow reads runtime configuration from Environment secrets and writes it only to temporary runner files.

### Required for all deployment backends

Create these Environment secrets:

#### `CROWLER_CONFIG`

The complete deployment `config.yaml` content.

#### `CROWLER_ENV`

The complete deployment `.env` content.

At minimum it must contain non-empty values for:

```text
DOCKER_POSTGRES_PASSWORD
DOCKER_CROWLER_DB_USER
DOCKER_CROWLER_DB_PASSWORD
SEL_PASSWD
```

It should also contain the desired:

```text
CROWLER_VERSION
CROWLER_VDI_VERSION
```

Workflow-dispatch version inputs can override these two values for a particular deployment.

Do not commit production `.env` or `config.yaml` files to this repository.

## Helm/Kubernetes credentials and content

For `backend=helm`, also create the Environment secret:

### `KUBECONFIG`

The complete kubeconfig used to reach the target cluster.

The selected runner must be able to reach the Kubernetes API endpoint.

For private clusters, use a self-hosted runner with the required network access instead of exposing the cluster API publicly for CI/CD.

The workflow stores this kubeconfig under the GitHub runner temporary directory and removes only that temporary file. It does not overwrite a self-hosted runner operator's existing `~/.kube/config`.

On apply, the Helm path mirrors the normal repository runtime contract:

* `config.yaml` becomes the externally managed `crowler-config` ConfigMap;
* every key declared by the deployment `.env` becomes part of `crowler-secrets`;
* direct files under `user/agents`, `user/plugins`, `user/rules`, and `user/support` become the corresponding externally managed ConfigMaps;
* the chart is installed with `userContent.enabled=true` and those ConfigMap names;
* config, secrets, and user-content rollout tokens force workload updates when their externally managed data changes;
* Helm uses `--atomic --wait --timeout 10m` and then verifies the Engine, API, and Events rollouts.

Keep Kubernetes ConfigMap size limits in mind for large user support files. Large/binary artifacts should use a storage or artifact-distribution mechanism rather than being forced into a ConfigMap.

## Nomad credentials

For `backend=nomad`, create:

### `NOMAD_ADDR`

The Nomad API address, for example:

```text
https://nomad.example.internal:4646
```

### `NOMAD_TOKEN`

Optional when ACLs are disabled, otherwise the Nomad ACL token used by the deployment runner.

### `NOMAD_NAMESPACE`

Optional. If omitted, Nomad's default namespace is used.

The selected runner must be able to reach the Nomad API.

The Environment or repository variable `NOMAD_VERSION` can override the CLI version installed by the workflow. If not set, the workflow uses its documented default.

The downloaded Nomad archive is verified against HashiCorp's published SHA256SUMS before installation.

## Plan before apply

For a new environment, run the deployment workflow with:

```text
operation = plan
```

first. After reviewing the result, run:

```text
operation = apply
```

`apply` is accepted only from `main`. Use GitHub Environment reviewers as the deployment approval gate for sensitive environments.

## Continuous deployment

Continuous deployment is available but disabled by default.

After `Validate deployment support` succeeds on `main`, the `Continuous deployment trigger` workflow dispatches an `apply` only when this repository variable is exactly:

```text
CROWLER_AUTO_DEPLOY=true
```

The following repository variables are then required:

```text
CROWLER_AUTO_DEPLOY_BACKEND=helm
CROWLER_AUTO_DEPLOY_ENVIRONMENT=production
CROWLER_AUTO_DEPLOY_RUNNER=ubuntu-latest
```

`CROWLER_AUTO_DEPLOY_BACKEND` may be either `helm` or `nomad`.

For private targets, set `CROWLER_AUTO_DEPLOY_RUNNER` to the label of a self-hosted runner that can reach the target.

Even when continuous deployment is enabled, GitHub Environment protection rules still apply.

## Supply-chain hardening

Third-party GitHub Actions in the repository are pinned to immutable commit SHAs instead of floating major-version tags. The corresponding tag is retained as a comment for readability.

Downloaded deployment binaries are checksum-verified before installation.

When updating an action or downloaded CLI, verify the new release from the official upstream project rather than changing the pin blindly.

## Recommended production model

Use these controls together:

1. protect `main` and require the `Validation gate` status;
2. require pull requests for deployment-support changes;
3. run the native runtime smoke workflow for important release/deployment milestones;
4. use a protected GitHub Environment for production;
5. store deployment credentials only as Environment secrets;
6. use self-hosted runners for private Kubernetes or Nomad control planes;
7. run `plan` before the first deployment to a new environment;
8. enable `CROWLER_AUTO_DEPLOY` only after manual deployment has been tested successfully;
9. keep Terraform apply outside ephemeral CI until remote state locking and persistence are configured.

## AI-assisted operation

The AI skill `.agents/skills/deploy-github-actions/SKILL.md` describes the same deployment boundaries, secrets, approval model, plan/apply sequence, runtime smoke workflow, and safety constraints for compatible agents.

Cross-backend validation guidance is in `.agents/skills/validate-deployment/SKILL.md`.

## Sensitive-file cleanup

The deployment workflow removes generated `.env`, `config.yaml`, and its temporary kubeconfig in an `always()` cleanup step.

This reduces credential persistence on the runner, but self-hosted runner operators must still secure runner hosts, logs, caches, and work directories according to their own security requirements.
