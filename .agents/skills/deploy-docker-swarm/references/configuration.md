# Docker Swarm Deployment Reference

This reference supports the `deploy-docker-swarm` skill.

## Canonical Files

| Purpose | Path |
| --- | --- |
| Shared generator | `docker-compose/generate-docker-compose.sh` |
| Swarm guide | `docker-swarm/README.md` |
| Environment template | `common/env/env_template` |
| Local config | `common/config/config.default` |
| Remote bootstrap | `common/config/config.default.remote` |
| Repository agent rules | `AGENTS.md` |

## Generator

Enable Swarm generation with:

```bash
--swarm=yes
```
