---
name: deploy-docker-compose
description: Configure and generate Docker Compose deployments of The CROWler using the official zfpsystems pre-built images. Use when a user wants to install, deploy, scale, configure, or troubleshoot CROWler with Docker Compose.
---

# Deploy CROWler with Docker Compose

Use `docker-compose/generate-docker-compose.sh` as the canonical
Compose generator.

## Rules

1. CROWler services MUST use official images:
   - zfpsystems/crowler-db
   - zfpsystems/crowler-engine
   - zfpsystems/crowler-vdi
   - zfpsystems/crowler-api
   - zfpsystems/crowler-events

2. Do not add local `build:` directives.

3. Use `CROWLER_VERSION` for DB, Engine, API, and Events.

4. Use `CROWLER_VDI_VERSION` independently for VDI.

5. Read `docker-compose/README.md` before modifying deployment behavior.

6. Validate generated Compose files with:

   docker compose config

7. Never remove persistent volumes or use `docker compose down -v`
   unless the user explicitly requests destructive cleanup.