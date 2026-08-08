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

Edits on the host are therefore visible through the mounted directories.

## Docker Swarm

Docker Swarm does not use node-local bind mounts for these directories.

The generator converts each direct, non-hidden regular file into a versioned
Swarm config and mounts it at the corresponding `/app/user/...` path.

Swarm config files must be at most 500 KiB each.

For larger content, use an external/shared Swarm volume.

## File Placement

Examples:

```text
user/agents/acme-agent.yaml
user/plugins/acme-plugin.js
user/rules/acme-rule.yaml
user/support/acme-data.json
```

Keep filenames simple:

```text
letters numbers dot underscore dash
```

Do not store passwords, tokens, private keys, or other secrets here.
