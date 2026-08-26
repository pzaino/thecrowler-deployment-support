# The CROWler Deployment Support

Deployment tooling and documentation for running **The CROWler** with official
pre-built container images.

The CROWler source can be found at:

https://github.com/pzaino/thecrowler

AMD64 and ARM64 are supported. You can run the CROWler on common x86-64 systems as well as 64-bit ARM systems such as modern Raspberry Pis or big ARM servers. On smaller devices, start with a small deployment and scale according to the available CPU and memory.

## Deployment Guides

| Deployment method | Status | Documentation |
| --- | --- | --- |
| Docker Compose | **Available** | [Docker Compose](docker-compose/README.md) |
| Docker Swarm | **Available** | [Docker Swarm](docker-swarm/README.md) |
| Kubernetes | **Available** | [Kubernetes](kubernetes/README.md) |
| Helm | **Available** | [Helm](helm/README.md) |
| HashiCorp Nomad | **Available** | [HashiCorp Nomad](nomad/README.md) |
| Terraform | **Available** | [Terraform](terraform/README.md) |
| GitHub Actions CI/CD | **Available** | [GitHub Actions](docs/github-actions.md) |

## GitHub Actions CI/CD

The repository includes CI validation for deployment definitions and controlled
CD workflows for Helm/Kubernetes and HashiCorp Nomad.

Production deployments can be protected with GitHub Environments and required
reviewers. Continuous deployment after successful validation on `main` is
available as an explicit opt-in and is disabled by default.

Terraform is validated in CI, but Terraform `apply` is intentionally not run
from ephemeral GitHub runners until an operator configures persistent, locked
remote state.

See [GitHub Actions deployment automation](docs/github-actions.md).

## Not sure where to start?

Start with Docker Compose. You can move to an orchestrator later without changing the CROWler itself.

For a guided first deployment, including laptops, servers, and ARM64 systems such as Raspberry Pis, see [Getting started](docs/getting-started.md).

## Deployment Tutorials

The backend READMEs are the detailed reference guides. These tutorials explain how the pieces fit together and help you choose an operational path:

* [Getting started](docs/getting-started.md) - from a fresh clone to a first running CROWler deployment.
* [Choosing a deployment method](docs/choosing-a-deployment.md) - Compose, Swarm, Nomad, Kubernetes, Helm, Terraform, and CI/CD compared by use case.
* [Configuration models](docs/configuration.md) - `.env`, local `config.yaml`, remote bootstrap configuration, secrets, and user content.
* [Planning a production deployment](docs/production-deployment.md) - storage, external services, private control planes, plans, approvals, CI/CD, and cloud deployment boundaries.
* [GitHub Actions CI/CD](docs/github-actions.md) - validation, protected environments, manual deployment, and optional continuous deployment.

## Repository Root Is the Deployment Root

Run deployment commands from the repository root.

The normal workspace is:

```text
thecrowler-deployment-support/
├── .env
├── config.yaml
├── docker-compose.yml
├── user/
│   ├── agents/
│   ├── plugins/
│   ├── rules/
│   └── support/
├── common/
├── docker-compose/
├── docker-swarm/
├── kubernetes/
├── helm/
├── nomad/
└── terraform/
```

Create `.env`:

```bash
cp common/env/env_template .env
```

Create exactly one runtime configuration:

```bash
cp common/config/config.default config.yaml
```

or:

```bash
cp common/config/config.default.remote config.yaml
```

For the difference between these two models, see [Configuration models](docs/configuration.md).

## User Content

Deployment-specific CROWler content belongs under:

```text
user/agents
user/plugins
user/rules
user/support
```

The stable runtime contract is:

```text
/app/user/agents
/app/user/plugins
/app/user/rules
/app/user/support
```

See [user/README.md](user/README.md).

## Official Images

| Component | Docker image |
| --- | --- |
| Database | `zfpsystems/crowler-db` |
| Engine | `zfpsystems/crowler-engine` |
| VDI | `zfpsystems/crowler-vdi` |
| API | `zfpsystems/crowler-api` |
| Events | `zfpsystems/crowler-events` |

`CROWLER_VERSION` controls DB, Engine, API, and Events.

`CROWLER_VDI_VERSION` controls VDI independently.

## Nomad

The Nomad backend uses:

* HCL jobspecs
* official Docker images
* Nomad native service discovery
* Nomad Variables for root `.env` values
* dynamic host volumes for bundled PostgreSQL
* allocation-local delivery of `config.yaml` and `user/*`

See [HashiCorp Nomad deployment guide](nomad/README.md).

## Terraform

Terraform orchestrates the existing Nomad and Helm/Kubernetes deployment
definitions rather than duplicating their workload topology.

See [Terraform deployment guide](terraform/README.md).

## Contributing

The CROWler has already thousands of active users, or so GitHub and Docker Hub stats say.
However, if you find anything wrong with any of the deployment support tools in this
repository, please feel free to fix the issue and open an PR with the fix, thank you!
