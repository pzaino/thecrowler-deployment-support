# Terraform Deployment Support

Terraform is an orchestration layer over the CROWler deployment backends
already maintained in this repository.

It does **not** redefine CROWler containers, services, or workload topology.

Supported Terraform targets:

```text
terraform/nomad/  -> reuses nomad/crowler.nomad.hcl
terraform/helm/   -> reuses helm/thecrowler/
```

## Requirements

* Terraform 1.15+
* root `.env`
* root `config.yaml`
* root `user/`
* `jq`

Nomad target additionally requires Nomad 1.10+ and a reachable Nomad cluster.

Helm target additionally requires Kubernetes 1.27+ and a valid kubeconfig.

Current provider constraints:

```text
hashicorp/nomad      ~> 2.6
hashicorp/helm       ~> 3.2
hashicorp/kubernetes ~> 3.2
```

## Repository Root Is the Execution Root

Run Terraform through:

```bash
./terraform/run.sh ...
```

from the repository root.

Do not normally `cd terraform/nomad` or `cd terraform/helm`.

The wrapper uses Terraform `-chdir` while keeping root `.env`, `config.yaml`,
and `user/` as the CROWler deployment inputs.

## Root Inputs

```text
.env
config.yaml
user/
├── agents/
├── plugins/
├── rules/
└── support/
```

Image versions come from root `.env`.

Sensitive `.env` values are passed to provider write-only attributes rather
than normal stateful Terraform attributes.

## Secret State Model

### Nomad

Terraform writes:

```text
nomad/jobs/crowler/env
```

using:

```text
nomad_variable.items_wo
```

### Kubernetes

Terraform writes the release Secret using:

```text
kubernetes_secret_v1.data_wo
```

Current providers specifically expose these write-only fields so the payload is
not persisted in Terraform state.

Still protect Terraform state, saved plans, backend credentials, Nomad tokens,
and kubeconfig normally.

## Nomad

Initialize:

```bash
./terraform/run.sh nomad init
```

Optional local values:

```bash
cp terraform/nomad/terraform.tfvars.example terraform/nomad/terraform.tfvars
```

Validate:

```bash
./terraform/run.sh nomad validate
```

Plan:

```bash
./terraform/run.sh nomad plan
```

Apply:

```bash
./terraform/run.sh nomad apply
```

Terraform directly manages:

* the existing CROWler Nomad job
* the root environment Nomad Variable
* optionally the PostgreSQL dynamic host volume

### Reusing the Existing Jobspec

The source of truth remains:

```text
nomad/crowler.nomad.hcl
```

The jobspec currently uses repository-root-relative `file()` and `fileset()`
functions.

Terraform runs with `-chdir`, so `terraform/nomad/locals.tf` adapts only the
submitted jobspec string to absolute repository paths. The source Nomad file is
not modified.

The Nomad provider requires:

```hcl
hcl2 {
  allow_fs = true
}
```

for those filesystem functions.

### Tracking config.yaml and user/*

The Nomad provider documents that Terraform cannot independently detect
changes that occur only in files loaded by HCL filesystem functions.

The Terraform configuration therefore hashes:

```text
config.yaml
user/agents/*
user/plugins/*
user/rules/*
user/support/*
```

and appends a harmless digest comment to the submitted jobspec.

Changing deployment content therefore creates a Terraform-visible Nomad job
update.

### PostgreSQL Volume Protection

Terraform can create:

```text
crowler-db-data
```

through the Nomad `mkdir` dynamic host-volume plugin.

The resource requests:

```text
single-node-single-writer
file-system
```

and contains:

```hcl
lifecycle {
  prevent_destroy = true
}
```

because destroying a Nomad dynamic host volume can destroy PostgreSQL data.

A full Terraform destroy is intentionally prevented from silently deleting the
database volume.

To use storage managed outside this Terraform root:

```hcl
manage_database_volume = false
database_volume_source = "existing-volume-name"
```

## Helm / Kubernetes

Initialize:

```bash
./terraform/run.sh helm init
```

Optional local values:

```bash
cp terraform/helm/terraform.tfvars.example terraform/helm/terraform.tfvars
```

Validate:

```bash
./terraform/run.sh helm validate
```

Plan:

```bash
./terraform/run.sh helm plan
```

Apply:

```bash
./terraform/run.sh helm apply
```

Terraform manages:

* the namespace when requested
* root `config.yaml` ConfigMap
* write-only Kubernetes Secret
* user agents ConfigMap
* user plugins ConfigMap
* user rules ConfigMap
* user support ConfigMap
* the existing CROWler Helm chart release

The chart remains the workload source of truth.

## Helm user/* delivery

The Helm chart now exposes:

```yaml
userContent:
  enabled: true
  agentsConfigMap: ...
  pluginsConfigMap: ...
  rulesConfigMap: ...
  supportConfigMap: ...
  rolloutToken: ...
```

Terraform creates those ConfigMaps from root `user/`.

The runtime targets remain:

```text
/app/user/agents
/app/user/plugins
/app/user/rules
/app/user/support
```

Terraform also computes a content digest and supplies it as the chart rollout
token, so Engine/API/Events roll when user content changes.

Kubernetes ConfigMaps are for relatively small UTF-8 text content. Use a PVC,
object storage, or another artifact mechanism for large/binary support data.

## Terraform State

This repository intentionally does not force a remote Terraform backend.

For production, configure a remote backend with appropriate:

* encryption
* locking
* backups
* access control

Never commit:

```text
terraform.tfstate
terraform.tfstate.*
terraform.tfvars
*.tfplan
```

Commit `.terraform.lock.hcl` after `terraform init`.

## Why Terraform Does Not Wrap Compose / Swarm

Compose and Swarm already have direct deployment generators and lifecycle
commands.

Wrapping those commands in Terraform `local-exec` would add state without
meaningful provider-backed resource management.

Terraform support is therefore focused on:

```text
Nomad
Kubernetes + Helm
```

Cloud infrastructure modules can be added later without changing the CROWler
runtime definitions.
