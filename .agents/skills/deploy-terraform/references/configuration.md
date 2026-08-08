# Terraform Deployment Reference

## Minimum Terraform

```text
1.15
```

## Provider Constraints

```text
hashicorp/nomad      ~> 2.6
hashicorp/helm       ~> 3.2
hashicorp/kubernetes ~> 3.2
```

## Commands

Nomad:

```bash
./terraform/run.sh nomad init
./terraform/run.sh nomad validate
./terraform/run.sh nomad plan
./terraform/run.sh nomad apply
```

Helm:

```bash
./terraform/run.sh helm init
./terraform/run.sh helm validate
./terraform/run.sh helm plan
./terraform/run.sh helm apply
```

## Root Inputs

```text
.env
config.yaml
user/
```

## Nomad

Runtime source:

```text
nomad/crowler.nomad.hcl
```

Secret path:

```text
nomad/jobs/crowler/env
```

Write-only attribute:

```text
nomad_variable.items_wo
```

Database storage:

```text
nomad_dynamic_host_volume
plugin_id=mkdir
single-node-single-writer
prevent_destroy=true
```

## Helm / Kubernetes

Runtime source:

```text
helm/thecrowler/
```

Terraform-managed objects:

```text
<release>-config
<release>-secrets
<release>-user-agents
<release>-user-plugins
<release>-user-rules
<release>-user-support
```

Write-only Secret attribute:

```text
kubernetes_secret_v1.data_wo
```

The chart consumes external objects and remains the workload source of truth.
