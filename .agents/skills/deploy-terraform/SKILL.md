---
name: deploy-terraform
description: Deploy, validate, plan, apply, inspect, or troubleshoot The CROWler through the repository Terraform orchestration layer. Use for Terraform-managed Nomad deployments, Terraform-managed Helm/Kubernetes releases, provider configuration, state safety, write-only secrets, Nomad dynamic host volumes, and config/user-content change tracking. Do not use Terraform to reimplement Docker Compose or Docker Swarm runtime definitions.
compatibility: Requires thecrowler-deployment-support, Terraform 1.15+, jq, and connectivity/credentials for the selected Nomad or Kubernetes backend.
metadata:
  project: thecrowler
  repository: pzaino/thecrowler-deployment-support
  deployment-backend: terraform
---

# Deploy The CROWler with Terraform

## Execution Root

Run:

```text
./terraform/run.sh ...
```

from the repository root.

## Sources of Truth

Inspect:

* `terraform/README.md`
* `terraform/run.sh`
* `terraform/nomad/`
* `terraform/helm/`
* `nomad/crowler.nomad.hcl`
* `helm/thecrowler/`
* `user/README.md`
* `AGENTS.md`

## Architectural Rule

Terraform orchestrates existing runtime definitions.

Nomad:

```text
Terraform -> hashicorp/nomad -> nomad/crowler.nomad.hcl
```

Kubernetes:

```text
Terraform -> ConfigMaps/Secret -> hashicorp/helm -> helm/thecrowler
```

Do not maintain a second workload topology in Terraform.

## Root Inputs

Require:

```text
.env
config.yaml
user/agents
user/plugins
user/rules
user/support
```

## Secrets

Nomad:

```text
nomad_variable.items_wo
```

Kubernetes:

```text
kubernetes_secret_v1.data_wo
```

Do not replace these with ordinary stateful secret attributes without explicit
acceptance of secret values in Terraform state.

Do not put credentials in `terraform.tfvars`.

## Nomad

```bash
./terraform/run.sh nomad init
./terraform/run.sh nomad validate
./terraform/run.sh nomad plan
./terraform/run.sh nomad apply
```

The Nomad Terraform layer must:

* reuse `nomad/crowler.nomad.hcl`
* enable HCL filesystem functions with `allow_fs = true`
* adapt root-relative jobspec filesystem calls to absolute paths in memory
* hash root config/user files
* include that digest in the submitted jobspec
* protect the database dynamic host volume with `prevent_destroy`

## Helm

```bash
./terraform/run.sh helm init
./terraform/run.sh helm validate
./terraform/run.sh helm plan
./terraform/run.sh helm apply
```

Terraform manages:

* namespace when requested
* runtime ConfigMap
* write-only Secret
* four user-content ConfigMaps
* existing CROWler Helm release

Do not duplicate Deployment/StatefulSet/Service objects in Terraform.

## State

Do not commit:

```text
terraform.tfstate
terraform.tfstate.*
terraform.tfvars
*.tfplan
```

Commit `.terraform.lock.hcl`.

Recommend an encrypted/locked remote backend for production.

## Safety

Never:

* destroy the Nomad PostgreSQL volume as routine cleanup
* put application secrets in ordinary Terraform stateful attributes when write-only equivalents exist
* commit local state or tfvars
* wrap Compose/Swarm in local-exec merely to claim Terraform support
* replace official CROWler images with local builds
