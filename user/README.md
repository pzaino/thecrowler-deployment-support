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

When the operator runs the Nomad CLI from the repository root, HCL `fileset()`
enumerates user files and `file()` reads them locally. Nomad embeds them into
the submitted job, renders them into allocation-local directories, and the
Docker driver mounts those directories read-only at `/app/user/...`.

Use artifact/object storage or shared volumes for large binaries, datasets, or
frequently changing support content.

## Kubernetes / Helm

Kubernetes and Helm use their backend-specific configuration/volume delivery
mechanisms while preserving the same `/app/user/...` runtime contract.

## File Placement

Examples:

```text
user/agents/acme-agent.yaml
user/plugins/acme-plugin.js
user/rules/acme-rule.yaml
user/support/acme-data.json
```

Do not store passwords, tokens, private keys, or other secrets here.
