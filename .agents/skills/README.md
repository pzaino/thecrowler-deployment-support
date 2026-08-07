# CROWler Deployment Agent Skills

This directory contains Agent Skills for working with
`thecrowler-deployment-support`.

The skills follow the open Agent Skills `SKILL.md` format and provide
task-specific workflows for AI agents working with CROWler deployments.

Repository-wide invariants are defined in the root `AGENTS.md`.
Deployment-specific operational workflows belong in the individual skills.

## Available Skills

| Skill | Purpose | Status |
| --- | --- | --- |
| `deploy-docker-compose` | Generate, deploy, validate, scale, and troubleshoot Docker Compose CROWler deployments | Available |
| `deploy-docker-swarm` | Generate, deploy, validate, scale, and troubleshoot Docker Swarm CROWler deployments | Available |
| `validate-deployment` | Validate CROWler deployment topology, images, configuration, persistence, and safety across deployment backends | Planned |
| `deploy-nomad` | Deploy CROWler with HashiCorp Nomad | Planned |
| `deploy-kubernetes` | Deploy CROWler with Kubernetes | Planned |
| `deploy-helm` | Deploy CROWler using the CROWler Helm chart | Planned |

Only create a deployment-specific skill when the corresponding deployment
backend is actually supported by this repository.

## Skill Design Principles

Skills in this repository should:

* describe a repeatable operational workflow
* keep repository-wide invariants in `AGENTS.md`
* keep task-specific instructions in `SKILL.md`
* use `references/` for detailed technical information
* use the live deployment generator or manifests as the behavioral source of truth
* avoid duplicating large human-facing deployment guides
* never contain production credentials
* never make destructive cleanup a default troubleshooting action
* never replace official CROWler images with source builds unless explicitly requested
* validate deployment output before declaring success

## Agent Skills Format

Each skill lives in its own directory:

```text
<skill-name>/
├── SKILL.md
└── references/
    └── ...
```

`SKILL.md` contains the activation metadata and operational workflow.

Files under `references/` contain technical information that should only be
loaded when needed.

## Agents skills location

Skills are located under:

```text
.agents/skills/
```
