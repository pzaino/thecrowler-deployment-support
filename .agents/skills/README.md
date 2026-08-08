# CROWler Deployment Agent Skills

Repository-wide invariants are defined in the root `AGENTS.md`.

Deployment-specific operational workflows belong in individual skills.

## Available Skills

| Skill | Purpose | Status |
| --- | --- | --- |
| `deploy-docker-compose` | Deploy and troubleshoot single-host Docker Compose installations | Available |
| `deploy-docker-swarm` | Deploy and troubleshoot Docker Swarm stacks | Available |
| `deploy-kubernetes` | Deploy and troubleshoot raw Kubernetes manifests | Available |
| `deploy-helm` | Install, configure, upgrade, and troubleshoot the CROWler Helm chart | Available |
| `deploy-nomad` | Deploy and troubleshoot HashiCorp Nomad installations | Available |
| `validate-deployment` | Cross-backend deployment validation | Planned |

## Skill Location

In the repository:

```text
.agents/skills/
```

This review ZIP intentionally exposes the directory as:

```text
agents/skills/
```

Rename `agents/` to `.agents/` when merging.

Each skill should keep workflow instructions in `SKILL.md` and detailed
technical facts in `references/`.
