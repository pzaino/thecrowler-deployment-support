# GitHub Actions deployment automation

This repository includes GitHub Actions workflows for validating deployment definitions and deploying The CROWler.

## Workflows

### `Validate deployment support`

Runs on pull requests and pushes to `main`.

It validates:

* shell deployment scripts with ShellCheck;
* required repository structure;
* the Helm chart with `helm lint` and `helm template`;
* Terraform formatting and validation for both `terraform/helm` and `terraform/nomad`.

This workflow does not connect to a live deployment target and does not deploy anything.

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

Terraform remains validated by CI but is not automatically applied. The Terraform roots currently leave backend selection to the operator, and production CI/CD should not run state-changing Terraform operations from an ephemeral runner until an encrypted, locked remote state backend has been configured.

## GitHub Environment setup

Create a GitHub Environment such as:

```text
production
```

For production, configure required reviewers on the Environment so `apply` runs require approval.

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

The workflow-dispatch version inputs can override these two values for a particular deployment.

Do not commit production `.env` or `config.yaml` files to this repository.

## Helm/Kubernetes credentials

For `backend=helm`, also create:

### `KUBECONFIG`

The complete kubeconfig used to reach the target cluster.

The selected runner must be able to reach the Kubernetes API endpoint.

For private clusters, use a self-hosted runner with the required network access instead of exposing the cluster API publicly for CI/CD.

The workflow:

1. validates the chart;
2. verifies cluster connectivity;
3. creates or updates the `crowler-config` ConfigMap;
4. creates or updates the `crowler-secrets` Secret;
5. runs `helm upgrade --install`;
6. waits for Engine, API, and Events deployments to roll out successfully.

The Helm deployment uses image versions from `CROWLER_ENV` unless workflow inputs override them.

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

The workflow delegates validation, environment synchronization, planning, and deployment to the existing Nomad scripts.

## Plan before apply

For a new environment, run the deployment workflow with:

```text
operation = plan
```

first.

After reviewing the result, run:

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

`CROWLER_AUTO_DEPLOY_BACKEND` may be either:

```text
helm
nomad
```

For private targets, set `CROWLER_AUTO_DEPLOY_RUNNER` to the label of a self-hosted runner that can reach the target.

Even when continuous deployment is enabled, GitHub Environment protection rules still apply. A protected `production` Environment can therefore require human approval before the dispatched deployment job receives production secrets or starts applying changes.

## Recommended production model

Use the following controls together:

1. require the validation workflow on changes to `main`;
2. use a protected GitHub Environment for production;
3. store deployment credentials only as Environment secrets;
4. use self-hosted runners for private Kubernetes or Nomad control planes;
5. run `plan` before the first deployment to a new environment;
6. enable `CROWLER_AUTO_DEPLOY` only after manual deployment has been tested successfully;
7. keep Terraform apply outside ephemeral CI until remote state locking and persistence are configured.

## Sensitive-file cleanup

The deployment workflow removes generated `.env`, `config.yaml`, and kubeconfig files in an `always()` cleanup step.

This reduces credential persistence on the runner, but self-hosted runner operators must still secure runner hosts, logs, caches, and work directories according to their own security requirements.
