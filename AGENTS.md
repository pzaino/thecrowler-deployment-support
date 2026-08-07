# AI Agent Instructions

This repository deploys pre-built CROWler artifacts.

## Repository purpose

Do not build The CROWler from source in this repository.

Source development belongs in:
https://github.com/pzaino/thecrowler

## Official images

Use only:

- zfpsystems/crowler-db
- zfpsystems/crowler-engine
- zfpsystems/crowler-vdi
- zfpsystems/crowler-api
- zfpsystems/crowler-events

unless the user explicitly requests another registry.

## Deployment documentation

Read the README for the deployment backend being modified:

- Docker Compose: docker-compose/README.md
- Nomad: nomad/README.md
- Kubernetes: kubernetes/README.md
- Helm: helm/README.md

## Skills

Task-specific AI instructions are under `skills/`.
