# CROWler deployment configuration

Every deployment backend in this repository uses the same two root-level
inputs:

```text
.env
config.yaml
```

Those files describe two different kinds of configuration:

* `.env` contains deployment environment values, credentials, image versions,
  and variables consumed by containers or deployment tooling;
* `config.yaml` contains the CROWler runtime configuration, or the bootstrap
  information required to retrieve that configuration remotely.

Keeping this distinction clear makes it easier to move the same deployment
between Docker Compose, Swarm, Nomad, Kubernetes, Terraform, and CI/CD.

## Create `.env`

Start from the provided template:

```bash
cp common/env/env_template .env
```

Edit the resulting file for your environment.

Important values used across the deployment backends include:

```text
DOCKER_POSTGRES_PASSWORD
DOCKER_CROWLER_DB_USER
DOCKER_CROWLER_DB_PASSWORD
SEL_PASSWD
CROWLER_VERSION
CROWLER_VDI_VERSION
```

Do not commit a populated `.env` file.

## Choose one `config.yaml` model

The repository provides two starting points.

### Local runtime configuration

Use:

```bash
cp common/config/config.default config.yaml
```

when the deployed `config.yaml` should contain the actual CROWler runtime
configuration.

This model contains sections such as database and crawler settings directly in
the file. Environment-variable references are resolved by the running CROWler
components.

This is normally the simplest choice for:

* local deployments;
* Docker Compose;
* standalone servers;
* smaller environments;
* deployments where configuration is managed together with the runtime.

### Remote configuration bootstrap

Use:

```bash
cp common/config/config.default.remote config.yaml
```

when CROWler should retrieve its real configuration from a remote distribution
service.

This file contains a `remote` section describing where the configuration can be
fetched, including host, path, port, authentication, timeout, and SSL/TLS
settings.

This model is useful when many CROWler instances or environments should obtain
configuration from a central source rather than carrying the full runtime
configuration in each deployment.

## Do not combine the two templates

Choose one configuration model and create one root `config.yaml`.

The deployment backends expect that file to represent the effective bootstrap
configuration for Engine, API, and Events.

## Where `config.yaml` goes

The stable runtime target is:

```text
/app/config.yaml
```

How it gets there depends on the backend:

| Backend | Delivery mechanism |
| --- | --- |
| Docker Compose | Docker Compose config |
| Docker Swarm | versioned Swarm config |
| Kubernetes | ConfigMap |
| Helm | external or chart-managed ConfigMap |
| Nomad | allocation template generated from the repository-root file |
| Terraform + Helm | Terraform-managed Kubernetes ConfigMap |
| Terraform + Nomad | existing Nomad jobspec with Terraform-visible content tracking |
| GitHub Actions | Environment secret materialized temporarily on the runner, then delivered through Helm or Nomad tooling |

## Deployment-specific agents, plugins, rules, and support files

Do not put deployment-specific CROWler content into the built-in image
directories.

Use:

```text
user/
├── agents/
├── plugins/
├── rules/
└── support/
```

These map to:

```text
/app/user/agents
/app/user/plugins
/app/user/rules
/app/user/support
```

See [User deployment content](../user/README.md) for backend-specific delivery
behavior and size limitations.

## Secrets

Treat `.env` and any configuration containing sensitive values as secrets.

Do not commit:

```text
.env
production config.yaml files containing secrets
values.private.yaml
terraform.tfvars
terraform.tfstate
terraform.tfstate.*
*.tfplan
kubeconfig files
Nomad ACL tokens
```

For Kubernetes production deployments, prefer Kubernetes Secrets or an
external secret-management workflow rather than embedding credentials in
ordinary configuration files.

For Nomad, the deployment tooling synchronizes environment values to a Nomad
Variable rather than placing them in the jobspec.

For GitHub Actions, store deployment inputs in protected GitHub Environment
secrets.

## Local versus external services

The deployment backends can use bundled services or external infrastructure in
several places.

Typical examples are:

* bundled PostgreSQL versus an externally managed PostgreSQL service;
* locally deployed VDI instances versus an external Selenium/VDI endpoint;
* optional Jaeger and Pushgateway services.

The exact switches differ by backend, so use the backend guide after deciding
which services belong inside the CROWler deployment boundary.

## Configuration changes and rollouts

Changing `config.yaml` does not always mean that already-running containers or
pods automatically consume the new file.

The repository handles this differently by backend:

* Docker Compose recreates services when the generated deployment changes;
* Docker Swarm uses content-hashed immutable configs;
* Kubernetes raw manifests require a rollout restart after updating the
  ConfigMap because the file is mounted using `subPath`;
* Helm can use rollout tokens or chart-managed content hashes;
* Nomad embeds the file into allocation templates;
* Terraform adds content digests where required so changes are visible to
  planning;
* GitHub Actions uses the underlying Helm or Nomad rollout behavior.

Always follow the update procedure documented for the backend you are using.

## Validate configuration before production deployment

At minimum, run the validation command associated with your backend before
applying changes:

```text
Docker Compose: docker compose config
Docker Swarm:   docker stack config -c docker-compose.yml
Kubernetes:     kubectl apply --dry-run=client -R -f kubernetes/base/
Helm:           helm lint helm/thecrowler
Nomad:          ./nomad/deploy.sh validate
Terraform:      ./terraform/run.sh <helm|nomad> validate
```

Validation catches structural deployment problems. It does not prove that all
external dependencies, credentials, networks, or target services are healthy.
