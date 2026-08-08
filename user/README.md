# User Deployment Content

This directory contains deployment-specific CROWler content supplied by the
user.

Keep the four categories grouped here:

```text
user/
├── agents/
├── plugins/
├── rules/
└── support/
```

## Host and Container Paths

The canonical mapping is:

```text
user/agents   -> /app/user/agents
user/plugins  -> /app/user/plugins
user/rules    -> /app/user/rules
user/support  -> /app/user/support
```

All source paths are relative to the repository root.

## Docker Compose

Docker Compose mounts these directories read-only.

## Docker Swarm

Docker Swarm converts each direct, non-hidden regular file into a versioned
Swarm config and mounts it at the corresponding `/app/user/...` path.

Swarm config files must be at most 500 KiB each.

## HashiCorp Nomad

Nomad does not require the repository directories to exist on every client.

The Nomad HCL parser reads them on the operator machine, renders them into the
allocation, and mounts allocation-local content at `/app/user/...`.

## Terraform

Terraform Nomad reuses the same Nomad content-delivery mechanism and adds file
hashes so changes are visible to Terraform state planning.

Terraform Helm creates four Kubernetes ConfigMaps from root `user/` and passes
them to the Helm chart `userContent` contract.

Kubernetes ConfigMap delivery is intended for small UTF-8 text files. Large or
binary support data should use persistent/shared storage or object/artifact
storage.

## File Placement

Examples:

```text
user/agents/acme-agent.yaml
user/plugins/acme-plugin.js
user/rules/acme-rule.yaml
user/support/acme-data.json
```

Do not store passwords, tokens, private keys, or other secrets here.
