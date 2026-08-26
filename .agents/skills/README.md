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
| `deploy-terraform` | Orchestrate Nomad and Helm/Kubernetes deployments with Terraform | Available |
| `deploy-github-actions` | Configure and operate GitHub Actions CI/CD deployment automation | Available |
| `validate-deployment` | Cross-backend deployment validation for humans, CI, and agents | Available |

## Choosing a Skill

Use the skill matching the deployment backend the user has selected.

When the user has not selected a backend yet, inspect:

```text
docs/choosing-a-deployment.md
```

before choosing one on their behalf.

For validation requests, use `validate-deployment` first and then the backend-specific skill to investigate any failure.

For GitHub-hosted deployment automation, use `deploy-github-actions`. It orchestrates the existing Helm/Kubernetes or Nomad paths and does not provision the underlying cloud or cluster infrastructure.

## Skill Location

Skills are stored in:

```text
.agents/skills/
```

Each skill directory contains a `SKILL.md` with YAML front matter describing its purpose, compatibility, and deployment backend.

Validate the complete skill set with:

```bash
bash ./scripts/validate-deployment-support.sh skills
```
