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
* AI deployment skill structure and metadata;
* generated Docker Compose output;
* generated Docker Swarm output, including Swarm-specific user-content/config rules;
* raw Kubernetes manifests with client-side validation;
* the Helm chart with linting and rendering;
* the Nomad jobspec with preflight, formatting, and `nomad job validate`;
* Terraform formatting and validation for both `terraform/helm` and `terraform/nomad`.

These checks are non-destructive. They do not connect to a production target and do not deploy anything.

### `Smoke published CROWler deployment`

Runs on demand through `workflow_dispatch`.

The smoke workflow uses native GitHub-hosted AMD64 and ARM64 runners. For the selected CROWler and VDI image tags it:

1. generates a minimal Docker Compose deployment;
2. validates the generated Compose configuration;
3. pulls the official DB, Engine, API, Events, and VDI images;
4. verifies that native image selection resolves to the expected `linux/amd64` or `linux/arm64` architecture;
5. creates the Compose containers without starting a production workload;
6. removes the ephemeral smoke resources.

Use this before a deployment when you want stronger assurance that published multi-architecture artifacts are available and compatible with the generated Compose topology.

It intentionally does not run on every pull request because the VDI image is large and registry-dependent.

### `Deploy The CROWler`

Runs through `workflow_dispatch` and supports:

* Helm/Kubernetes;
* HashiCorp Nomad;
* `plan`;
* `apply`;
* GitHub-hosted or self-hosted runners;
* CROWler and VDI image-version overrides.

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

## Helm/Kubernetes credentials

For `backend=helm`, also create the Environment secret:

### `KUBECONFIG`

The complete kubeconfig used to reach the target cluster.

The selected runner must be able to reach the Kubernetes API endpoint.

For private clusters, use a self-hosted runner with the required network access instead of exposing the cluster API publicly for CI/CD.

The workflow validates the chart, verifies cluster connectivity, creates or updates runtime ConfigMap and Secret objects, runs `helm upgrade --install`, and waits for Engine, API, and Events rollouts.

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

## Plan before apply

For a new environment, run the deployment workflow with:

```text
operation = plan
```

first. After reviewing the result, run:

```text
operation = apply
```

Use GitHub Environment reviewers as the deployment approval gate for sensitive environments.

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

## Recommended production model

Use these controls together:

1. require `Validate deployment support` on changes to `main`;
2. run the native image smoke workflow for important release/deployment milestones;
3. use a protected GitHub Environment for production;
4. store deployment credentials only as Environment secrets;
5. use self-hosted runners for private Kubernetes or Nomad control planes;
6. run `plan` before the first deployment to a new environment;
7. enable `CROWLER_AUTO_DEPLOY` only after manual deployment has been tested successfully;
8. keep Terraform apply outside ephemeral CI until remote state locking and persistence are configured.

## AI-assisted operation

The AI skill `.agents/skills/deploy-github-actions/SKILL.md` describes the same deployment boundaries, secrets, approval model, plan/apply sequence, smoke workflow, and safety constraints for compatible agents.

Cross-backend validation guidance is in `.agents/skills/validate-deployment/SKILL.md`.

## Sensitive-file cleanup

The deployment workflow removes generated `.env`, `config.yaml`, and kubeconfig files in an `always()` cleanup step.

This reduces credential persistence on the runner, but self-hosted runner operators must still secure runner hosts, logs, caches, and work directories according to their own security requirements.
