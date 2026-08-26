# Getting started with The CROWler deployment support

This repository is for people who want to **run The CROWler using the official
pre-built images**.

You do not need to build The CROWler from source.

If you are developing The CROWler itself, use the main project repository:

https://github.com/pzaino/thecrowler

## The shortest path to a running CROWler

If this is your first deployment, start with Docker Compose on one machine.
That machine can be a laptop, workstation, server, VM, or a 64-bit ARM system
such as a modern Raspberry Pi.

The official CROWler images are published for both AMD64 and ARM64.

### 1. Clone the deployment repository

```bash
git clone https://github.com/pzaino/thecrowler-deployment-support.git
cd thecrowler-deployment-support
```

All commands in this repository are designed to run from the repository root.

### 2. Create your environment file

```bash
cp common/env/env_template .env
```

Open `.env` and set the values required for your deployment, especially the
passwords and image versions.

Do not commit `.env`.

### 3. Choose your CROWler configuration model

For a deployment where `config.yaml` contains the actual CROWler runtime
configuration:

```bash
cp common/config/config.default config.yaml
```

For a deployment where CROWler should bootstrap its real configuration from a
remote distribution service:

```bash
cp common/config/config.default.remote config.yaml
```

Choose one, then edit the resulting `config.yaml`.

See [Configuration models](configuration.md) for the difference between the
two approaches.

### 4. Generate a small Docker Compose deployment

A sensible first deployment is one Engine, one VDI, bundled PostgreSQL, and no
Pushgateway:

```bash
./docker-compose/generate-docker-compose.sh \
  -e=1 \
  -v=1 \
  --prom=no \
  --pg=yes
```

This creates:

```text
docker-compose.yml
```

### 5. Validate before starting

```bash
docker compose config
```

If validation succeeds, pull the official images:

```bash
docker compose pull
```

Then start the deployment:

```bash
docker compose up -d
```

### 6. Check that it is running

```bash
docker compose ps
```

For logs:

```bash
docker compose logs -f
```

At this point you have a normal CROWler deployment using the same official
images used by the larger orchestration backends in this repository.

## Running on a Raspberry Pi or another ARM64 system

Use a 64-bit operating system and a Docker installation capable of running
`linux/arm64` images.

Start small:

```bash
./docker-compose/generate-docker-compose.sh \
  -e=1 \
  -v=1 \
  --prom=no \
  --pg=yes
```

The VDI is normally one of the more resource-intensive components, so increase
Engine and VDI counts only after observing CPU and memory usage on the target
system.

This repository does not currently define a minimum Raspberry Pi model or RAM
size. Capacity depends on workload, browser activity, crawl concurrency, and
which optional services you enable.

## Adding deployment-specific content

You can add your own deployment-specific CROWler content without rebuilding the
images.

Use:

```text
user/
├── agents/
├── plugins/
├── rules/
└── support/
```

The deployment backends deliver those files to the stable runtime paths:

```text
/app/user/agents
/app/user/plugins
/app/user/rules
/app/user/support
```

See [User deployment content](../user/README.md).

## Moving beyond one machine

You do not need to redesign CROWler when you move to an orchestrator. Choose the
backend that matches the infrastructure you already operate.

A common progression is:

```text
Laptop / Raspberry Pi / single server
                |
                v
         Docker Compose
                |
                v
   multi-node scheduler or cluster
        /                  \
       v                    v
Docker Swarm / Nomad     Kubernetes
                            |
                            v
                           Helm
                            |
                            v
                    Terraform / CI/CD
```

See [Choosing a deployment method](choosing-a-deployment.md).

## Existing Kubernetes or Nomad infrastructure

If you already have a cluster, you can skip Docker Compose entirely.

For Kubernetes, Helm is the recommended packaged deployment:

```bash
helm lint helm/thecrowler
helm template crowler helm/thecrowler --namespace crowler
```

Then follow [the Helm deployment guide](../helm/README.md).

For Nomad:

```bash
./nomad/deploy.sh validate
./nomad/deploy.sh plan
```

Then follow [the Nomad deployment guide](../nomad/README.md).

## Automating deployment

Once you have successfully deployed manually, GitHub Actions can validate and
deploy the same definitions.

The supported CD paths are:

```text
GitHub Actions -> Helm -> Kubernetes
GitHub Actions -> Nomad deployment scripts -> Nomad
```

For production, use protected GitHub Environments, deployment credentials stored
as Environment secrets, and approval gates where appropriate.

See [GitHub Actions deployment automation](github-actions.md).

## Hyperscalers

The CROWler can be deployed onto Kubernetes or Nomad infrastructure running in
cloud environments as long as the deployment runner can reach the cluster.

For example, an existing managed Kubernetes cluster can be targeted with Helm,
Terraform, or GitHub Actions.

This repository currently focuses on **deploying CROWler onto existing
infrastructure**. It does not yet provision cloud foundations such as VPCs,
managed Kubernetes clusters, load balancers, or cloud databases for AWS, Azure,
or Google Cloud.

That boundary is intentional: infrastructure provisioning and CROWler workload
deployment remain separate layers.

## Where to go next

* [Choose a deployment method](choosing-a-deployment.md)
* [Understand configuration models](configuration.md)
* [Plan a production deployment](production-deployment.md)
* [Docker Compose](../docker-compose/README.md)
* [Docker Swarm](../docker-swarm/README.md)
* [Kubernetes](../kubernetes/README.md)
* [Helm](../helm/README.md)
* [Nomad](../nomad/README.md)
* [Terraform](../terraform/README.md)
* [GitHub Actions CI/CD](github-actions.md)
