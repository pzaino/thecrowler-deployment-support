# Planning a production CROWler deployment

A production CROWler deployment is less about choosing the most complicated
orchestrator and more about making the operational boundaries explicit.

Before automating anything, decide where configuration, secrets, storage,
network access, and deployment approval should live.

## Start with a deployment that works manually

Use the same sequence regardless of backend:

```text
prepare configuration
        |
        v
validate deployment definitions
        |
        v
plan or dry-run where available
        |
        v
apply manually
        |
        v
verify runtime health
        |
        v
automate the known-good process
```

Do not make CI/CD the first time a new environment is ever deployed.

## Choose the runtime platform

For a single production host, Docker Compose may be sufficient if the
availability and recovery model matches your requirements.

For multi-node environments, use an orchestrator that your organization knows
how to operate:

* Docker Swarm;
* HashiCorp Nomad;
* Kubernetes, normally through Helm.

Terraform can manage the Nomad or Helm deployment when you want the CROWler
deployment represented in Terraform state.

See [Choosing a deployment method](choosing-a-deployment.md).

## Decide which services CROWler should own

The deployment examples can include services such as PostgreSQL, VDI, Jaeger,
and Pushgateway.

Production environments often move some of these outside the CROWler workload
boundary.

For example:

```text
Development / small deployment

CROWler deployment
├── PostgreSQL
├── VDI
├── Engine
├── API
├── Events
└── telemetry
```

may become:

```text
Production platform
├── managed / external PostgreSQL
├── persistent storage platform
├── observability platform
└── CROWler deployment
    ├── VDI
    ├── Engine
    ├── API
    └── Events
```

The repository supports external PostgreSQL with Helm and Nomad configuration.
Choose the boundary that matches your recovery, availability, and security
requirements.

## Treat PostgreSQL storage as persistent infrastructure

Do not treat database storage as disposable container state.

Backend-specific notes:

* Docker local volumes are tied to the Docker host unless you provide shared
  storage;
* Swarm does not make a local Docker volume highly available;
* the default Nomad bundled database uses a node-local dynamic host volume;
* Kubernetes requests persistent storage through a PVC;
* Terraform Nomad protects a managed database volume from automatic destroy.

If the database requires node-independent durability or managed backups, use a
storage solution appropriate for the platform or an external PostgreSQL
service.

Never delete persistent volumes as a routine troubleshooting action.

## Keep control planes private where possible

The deployment runner needs network access to the target scheduler API.

For Kubernetes this means the Kubernetes API endpoint.

For Nomad this means the Nomad API endpoint.

A private control plane does not need to be exposed publicly just to enable
CI/CD. GitHub Actions supports self-hosted runners, so a runner can live inside
the same trusted network as the target cluster.

Typical model:

```text
GitHub
  |
  | workflow job
  v
self-hosted runner inside trusted network
  |
  +--> Kubernetes API
  |
  +--> Nomad API
```

Secure the runner host because deployment credentials and temporary runtime
configuration exist there during the job.

## Separate configuration from secrets

The root deployment model uses:

```text
.env
config.yaml
```

For production automation, do not commit populated copies of these files.

With GitHub Actions, store their contents in protected Environment secrets:

```text
CROWLER_ENV
CROWLER_CONFIG
```

Kubernetes deployments should use Kubernetes Secrets or an external secret
workflow for runtime credentials.

Nomad deployments synchronize environment values into Nomad Variables.

See [Configuration](configuration.md).

## Use deployment environments

Create separate deployment environments rather than reusing one production
configuration everywhere.

For example:

```text
development
staging
production
```

Each environment can have its own:

* CROWler runtime configuration;
* credentials;
* image versions;
* database endpoint;
* scheduler endpoint;
* scaling values;
* deployment approval rules.

With GitHub Actions, represent these using GitHub Environments.

## Validate every change

The repository CI validates deployment definitions on pull requests and pushes
to `main`.

It checks:

* shell scripts with ShellCheck;
* required repository structure;
* Helm linting and templating;
* Terraform formatting and validation for Helm and Nomad roots.

These checks intentionally do not connect to production infrastructure.

They answer:

> Is the deployment definition structurally valid?

They do not answer:

> Can this particular production cluster successfully run it?

That second question belongs to planning, staging, deployment, and runtime
health checks.

## Plan before apply

Where the backend supports it, review a plan before changing production.

Nomad:

```bash
./nomad/deploy.sh plan
```

Terraform:

```bash
./terraform/run.sh nomad plan
./terraform/run.sh helm plan
```

GitHub Actions:

```text
operation = plan
```

For a new environment, run a plan before the first apply.

## Protect production deployment

A recommended GitHub Actions model is:

```text
Pull request
    |
    v
CI validation
    |
    v
merge to main
    |
    v
manual deployment dispatch or optional CD trigger
    |
    v
protected GitHub Environment
    |
    v
required reviewer approval
    |
    v
apply
```

This preserves automation without making production changes invisible or
uncontrolled.

See [GitHub Actions deployment automation](github-actions.md).

## Continuous deployment should be the final step

The repository can automatically dispatch a deployment after successful
validation on `main`, but this is disabled by default.

Before enabling it:

1. deploy the target manually;
2. confirm configuration and secrets are correct;
3. test the GitHub Actions `plan` path;
4. test a manually dispatched `apply`;
5. configure Environment protection;
6. only then enable automatic deployment.

The repository variable:

```text
CROWLER_AUTO_DEPLOY=true
```

is the explicit opt-in switch.

Protected GitHub Environments can still require approval even when automatic
dispatch is enabled.

## Terraform state in production

The Terraform roots deliberately do not force a particular backend.

Before using Terraform `apply` from CI/CD, configure remote state with the
properties your organization requires, normally including:

* persistence;
* encryption;
* state locking;
* backups;
* access control.

This is why the current GitHub Actions deployment workflow validates Terraform
but does not automatically execute state-changing Terraform operations.

## Cloud and hyperscaler deployments

The CROWler workload layer is intentionally independent of cloud provider.

For an existing managed Kubernetes cluster, the normal deployment stack can
look like:

```text
AWS / Azure / Google Cloud / other provider
                |
                v
        managed Kubernetes
                |
                v
              Helm
                |
                v
            The CROWler
```

or:

```text
cloud / datacenter infrastructure
                |
                v
              Nomad
                |
                v
            The CROWler
```

GitHub Actions can drive those deployments if the selected runner can reach the
cluster.

This repository currently does not create the underlying cloud network,
managed cluster, or managed database. Provision those separately, then use this
repository to deploy CROWler onto the resulting scheduler environment.

## Verify after deployment

A successful deployment command is not the same as a healthy application.

Use the backend's runtime inspection tools after every meaningful change.

Docker Compose:

```bash
docker compose ps
docker compose logs -f
```

Docker Swarm:

```bash
docker stack services crowler
docker stack ps crowler --no-trunc
```

Kubernetes / Helm:

```bash
kubectl get pods -n crowler
kubectl get services -n crowler
kubectl rollout status deployment/crowler-engine -n crowler
kubectl rollout status deployment/crowler-api -n crowler
kubectl rollout status deployment/crowler-events -n crowler
```

Nomad:

```bash
./nomad/deploy.sh status
./nomad/deploy.sh allocations
```

Production monitoring should additionally cover the external services and
storage on which the deployment depends.

## A useful maturity model

You do not need every production control on day one.

A practical evolution is:

```text
1. Known-good manual deployment
2. Repeatable configuration
3. Validation in CI
4. Plan before change
5. Protected automated apply
6. Runtime health verification
7. Optional continuous deployment
```

Move to the next stage when the previous one is understood and observable.
