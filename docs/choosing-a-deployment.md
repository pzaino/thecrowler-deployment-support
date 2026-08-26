# Choosing a CROWler deployment method

The CROWler can run in very small environments and in clustered environments.
The best deployment method depends less on CROWler itself and more on the
infrastructure you already operate.

If you are unsure, start with Docker Compose.

## Quick decision table

| Your environment | Recommended method | Why |
| --- | --- | --- |
| Laptop, workstation, VM, Raspberry Pi, single server | Docker Compose | Lowest operational complexity |
| Small Docker cluster | Docker Swarm | Multi-node scheduling without introducing a new platform |
| Existing Nomad environment | HashiCorp Nomad | Native scheduling, service discovery, and scaling |
| Existing Kubernetes cluster | Helm | Recommended packaged Kubernetes deployment |
| Kubernetes manifests need to remain explicit | Raw Kubernetes | Useful for inspection, debugging, and environments that intentionally avoid Helm |
| Existing Nomad or Kubernetes deployment managed as infrastructure state | Terraform | Declarative orchestration over the existing Nomad jobspec or Helm chart |
| Staging/production deployment driven from GitHub | GitHub Actions | CI validation, controlled plan/apply, protected environments, optional continuous deployment |
| Existing EKS, AKS, GKE, or other managed Kubernetes cluster | Helm or Terraform, optionally driven by GitHub Actions | CROWler deployment is independent of the Kubernetes provider |

## Docker Compose

Choose Docker Compose when everything should run on one Docker host.

It is the best place to start for:

* local development and testing;
* laptops and workstations;
* home servers;
* modern 64-bit Raspberry Pi systems;
* single cloud VMs;
* small standalone deployments.

The repository generator creates `docker-compose.yml` from your requested
Engine, VDI, PostgreSQL, telemetry, and resource-limit settings.

Use it when you want the shortest path from clone to running containers.

See [Docker Compose](../docker-compose/README.md).

## Docker Swarm

Choose Swarm when you already operate Docker across multiple hosts and want to
schedule CROWler as a Docker stack.

Compared with ordinary Compose, Swarm adds:

* multi-node scheduling;
* overlay networking;
* Swarm services;
* Swarm configs for runtime configuration and user content;
* service-level resource limits and restart policies.

Swarm is a natural next step for users who want multiple Docker nodes without
adopting Kubernetes or Nomad.

Remember that local Docker volumes are still node-local unless you provide a
shared storage solution. Treat bundled PostgreSQL storage accordingly.

See [Docker Swarm](../docker-swarm/README.md).

## HashiCorp Nomad

Choose Nomad when you want a dedicated scheduler with a smaller operational
surface than Kubernetes, or when your environment already uses HashiCorp
infrastructure.

The CROWler Nomad backend provides:

* native Nomad service discovery;
* Nomad Variables for environment values;
* multi-node scheduling;
* Engine-to-VDI service selection;
* dynamic host-volume support for bundled PostgreSQL;
* allocation-local delivery of CROWler configuration and user content.

It does not require Consul for the default deployment.

Nomad is a good fit for private infrastructure, homelabs, bare-metal fleets,
and organizations already operating Nomad.

See [HashiCorp Nomad](../nomad/README.md).

## Kubernetes

The repository contains raw Kubernetes manifests as a transparent reference
implementation.

Use them when:

* you need to inspect exactly which Kubernetes objects CROWler uses;
* you intentionally do not use Helm;
* you are learning or debugging the deployment;
* you need a starting point for platform-specific manifests.

For most normal Kubernetes installations, prefer Helm.

See [Kubernetes](../kubernetes/README.md).

## Helm

Helm is the recommended way to install CROWler on Kubernetes.

Choose it when you want:

* repeatable installation and upgrades;
* configurable replicas;
* bundled or external PostgreSQL;
* chart-managed or externally managed ConfigMaps and Secrets;
* predictable rollout behavior;
* one package that can be used across local Kubernetes, private clusters, and managed cloud Kubernetes.

The chart is the Kubernetes workload source of truth used by the Terraform Helm
backend as well.

See [Helm](../helm/README.md).

## Terraform

Terraform is not a separate CROWler workload implementation.

It orchestrates the deployment definitions already maintained in this
repository:

```text
Terraform -> nomad/crowler.nomad.hcl
Terraform -> helm/thecrowler/
```

Choose Terraform when your organization wants CROWler deployment changes to be
planned, applied, and tracked through Terraform state.

The Terraform support is currently focused on:

* Nomad;
* Kubernetes through Helm.

It intentionally does not wrap Docker Compose or Swarm using `local-exec`,
because that would add Terraform state without meaningful provider-backed
resource management.

For production, configure persistent, encrypted, locked remote state before
running state-changing Terraform operations from automation.

See [Terraform](../terraform/README.md).

## GitHub Actions CI/CD

GitHub Actions sits above the deployment backend. It is not another runtime.

The deployment relationship is:

```text
                     +-> Helm -> Kubernetes
GitHub Actions ------+
                     +-> Nomad scripts -> Nomad
```

Use it after the target deployment has been tested manually.

The repository supports:

* CI validation on pull requests and `main`;
* manually dispatched plans and deployments;
* GitHub Environment secrets;
* required reviewers and approval gates;
* GitHub-hosted or self-hosted runners;
* optional continuous deployment after successful validation.

Private clusters normally require a self-hosted runner that can reach the
Kubernetes or Nomad API.

See [GitHub Actions CI/CD](github-actions.md).

## What about AWS, Azure, and Google Cloud?

CROWler does not care which provider hosts the scheduler.

If you already have Kubernetes on EKS, AKS, GKE, or another provider, you can
deploy CROWler with Helm, Terraform, and GitHub Actions using the same workload
definitions.

Likewise, a reachable Nomad cluster can be deployed to with the Nomad backend
regardless of where those nodes run.

The current repository does **not** provision the cloud platform itself. It
does not yet create VPCs, EKS/AKS/GKE clusters, cloud load balancers, or managed
databases.

The current boundary is:

```text
Cloud / datacenter infrastructure
             |
             v
Existing Kubernetes or Nomad cluster
             |
             v
The CROWler deployment support
```

This separation keeps CROWler workload topology independent from a specific
cloud provider.

## A practical progression

A deployment can grow without forcing you to change everything at once:

```text
Docker Compose on one host
            |
            v
Docker Swarm / Nomad / Kubernetes
            |
            v
Helm or Terraform-managed desired state
            |
            v
CI/CD with protected production environments
```

Moving between these layers should be driven by operational needs, not by a
requirement from CROWler itself.
