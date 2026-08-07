# CROWler Deployment Agent Skills

This directory contains Agent Skills for working with
`thecrowler-deployment-support`.

The skills follow the open Agent Skills `SKILL.md` format and provide
task-specific workflows for AI agents working with CROWler deployments.

Repository-wide agent instructions are defined separately in `AGENTS.md`.

## Available Skills

| Skill                   | Purpose                                                                                                         | Status    |
| ----------------------- | --------------------------------------------------------------------------------------------------------------- | --------- |
| `deploy-docker-compose` | Generate, deploy, validate, scale, and troubleshoot Docker Compose CROWler deployments                          | Available |
| `validate-deployment`   | Validate CROWler deployment topology, images, configuration, persistence, and safety across deployment backends | Planned   |
| `deploy-nomad`          | Deploy CROWler with HashiCorp Nomad                                                                             | Planned   |
| `deploy-kubernetes`     | Deploy CROWler with Kubernetes                                                                                  | Planned   |
| `deploy-helm`           | Deploy CROWler using the CROWler Helm chart                                                                     | Planned   |

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

## Discovery

The Agent Skills specification defines the skill directory format but agent
hosts determine where project skills are discovered.

For broad repository-level agent compatibility, consider storing these skills
under:

```text
.agents/skills/
```

Some agent hosts also recognise locations such as:

```text
.github/skills/
.claude/skills/
```

Consult the documentation for the agent host being used.

MCP servers do not automatically discover repository skills. An MCP
integration must explicitly expose, install, or load these resources.

## Validation

Validate skill metadata and structure against the Agent Skills specification
before publishing changes.

Where supported, use the host's skill validation tooling or the Agent Skills
reference validator.

Treat skills as executable operational guidance and review changes to them with
the same care as deployment scripts.
