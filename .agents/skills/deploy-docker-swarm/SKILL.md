---

name: deploy-docker-swarm
description: Deploy, configure, scale, validate, update, inspect, or troubleshoot The CROWler with Docker Swarm using the official zfpsystems pre-built images. Use for CROWler Swarm stack generation, multi-node deployment, overlay networking, service and task inspection, image version selection, resource limits, persistent-storage planning, stack updates, and Swarm troubleshooting. Do not use for ordinary single-host Docker Compose deployment or for building CROWler images from source.
compatibility: Requires a checkout of thecrowler-deployment-support. Executing deployments requires Bash, Docker Engine with Swarm support, and access to a Swarm manager node.
metadata:
  project: thecrowler
  repository: pzaino/thecrowler-deployment-support
  deployment-backend: docker-swarm

---

# Deploy The CROWler with Docker Swarm

Use this skill for Docker Swarm deployment tasks in
`thecrowler-deployment-support`.

Docker Swarm currently shares the CROWler Compose generator but uses a
different deployment and runtime model.

## When to Use

Use this skill when the task involves:

* deploying CROWler across Docker Swarm nodes
* generating a CROWler stack with `--swarm=yes`
* configuring overlay networking
* inspecting Swarm services or tasks
* updating an existing CROWler stack
* troubleshooting failed Swarm scheduling
* selecting CROWler image versions for a stack
* configuring Swarm resource limits
* planning persistent storage for multi-node deployment
* reviewing published ports in a Swarm environment

## When Not to Use

Do not use this skill to:

* run a normal single-host Docker Compose deployment
* build CROWler binaries or images from source
* modify the CROWler core implementation
* develop CROWler plugins or rules
* deploy with Nomad, Kubernetes, or Helm

For single-host Docker Compose use:

`deploy-docker-compose`

Source development belongs in:

https://github.com/pzaino/thecrowler

## Repository Sources of Truth

Before making deployment assumptions, inspect:

* `docker-compose/generate-docker-compose.sh`
* `docker-swarm/README.md`
* `common/env/env_template`
* `common/config/config.default`
* `common/config/config.default.remote`
* `AGENTS.md`

The generator is authoritative for the stack topology it currently emits.

The Docker Swarm README is authoritative for the user-facing Swarm workflow.

If documentation and generated behavior disagree, report the discrepancy and
use observed generator behavior to describe what the current deployment
actually produces.

See:

`references/configuration.md`

for a condensed Swarm deployment reference.

## Official Image Contract

Use the official pre-built CROWler images unless the user explicitly requests
another registry:

* `zfpsystems/crowler-db`
* `zfpsystems/crowler-engine`
* `zfpsystems/crowler-vdi`
* `zfpsystems/crowler-api`
* `zfpsystems/crowler-events`

Do not add local `build:` directives.

Do not fall back to source builds when a Swarm node fails to pull an image.

Investigate the image tag, registry connectivity, or registry authentication
instead.

Official CROWler images are multi-platform. Do not force `linux/amd64`
without an explicit requirement.

## Version Contract

Use:

`CROWLER_VERSION`

for:

* DB
* Engine
* API
* Events

Use:

`CROWLER_VDI_VERSION`

independently for VDI.

Never invent image tags.

Prefer explicit versions for reproducible production deployments unless the
user specifically wants `latest`.

## Swarm Preconditions

Before deploying, verify:

1. Docker Engine is available.
2. Swarm mode is active.
3. The current node is a Swarm manager for stack-management operations.
4. Required registry images are reachable from nodes that may run CROWler tasks.
5. Required environment variables are available.
6. Persistent storage assumptions are appropriate for a multi-node deployment.

Useful checks include:

```bash
docker info
docker node ls
```

Do not initialize a new Swarm unless the user actually wants to create one.

## Required Deployment Inputs

Before generating a non-interactive stack, establish:

1. Number of Engine instances.
2. Number of VDI instances.
3. Whether bundled PostgreSQL is required.
4. Whether Pushgateway is required.
5. Whether API, Events, or Jaeger should be disabled.
6. Requested CPU or memory limits.
7. CROWler image version.
8. VDI image version.
9. Whether the deployment uses an external registry requiring authentication.
10. Any storage or placement requirements that materially affect Swarm scheduling.

Use information already supplied by the user.

Do not ask again for values already present in the environment or deployment
configuration.

## Generate the Stack

The canonical generator is:

`docker-compose/generate-docker-compose.sh`

Generate Swarm-oriented output with:

```bash
./docker-compose/generate-docker-compose.sh \
  -e=2 \
  -v=2 \
  --prom=yes \
  --pg=yes \
  --swarm=yes
```

For automated workflows, prefer explicit arguments so the generator does not
block waiting for interactive input.

The generated file remains:

`docker-compose.yml`

When changing Swarm generation behavior, modify the shared generator rather
than manually maintaining equivalent edits in generated stack files.

## Swarm-Specific Generator Behavior

With:

`--swarm=yes`

the current generator is expected to:

* use overlay networks
* emit `deploy.resources.limits`
* omit normal Compose `pull_policy`
* preserve the generated CROWler service topology
* preserve the official CROWler image references

Do not assume that every modern Docker Compose feature is supported by
`docker stack deploy`.

Docker Swarm stack deployment uses a Compose compatibility model that differs
from the normal Compose CLI runtime.

## Environment Handling

Never invent credentials.

Never expose secrets in logs or responses.

Do not overwrite an existing `.env` file unless explicitly requested.

Remember that Docker Swarm stack deployment does not perform `.env`
interpolation exactly like ordinary Docker Compose.

Before validation or deployment, ensure required interpolation variables are
present in the manager shell environment.

A typical pattern is:

```bash
set -a
. ./.env
set +a
```

Service-level `env_file:` handling is separate from interpolation.

Verify that any `env_file` path referenced in generated YAML is valid from the
deployment context.

## Validate Before Deploying

Validate the generated stack from a Swarm manager:

```bash
docker stack config -c docker-compose.yml
```

Validation must use the environment intended for the real deployment.

Also inspect the rendered configuration for:

* official CROWler image names
* expected versions
* Engine count
* VDI count
* valid Engine-to-VDI references
* overlay networks
* persistent volumes
* resource limits
* optional services
* published ports
* unsupported or ignored Compose fields

Do not claim a stack is deployable merely because the YAML parses.

## Deploy the Stack

When explicitly asked to deploy:

```bash
docker stack deploy \
  --compose-file docker-compose.yml \
  --resolve-image always \
  crowler
```

If registry authentication must be propagated to worker nodes, use the
appropriate registry authentication workflow and, when applicable:

```bash
docker stack deploy \
  --compose-file docker-compose.yml \
  --resolve-image always \
  --with-registry-auth \
  crowler
```

Do not add `--with-registry-auth` unnecessarily.

## Inspect Deployment State

After deployment, inspect:

```bash
docker stack services crowler
docker stack ps crowler
```

For a failing service:

```bash
docker service ps SERVICE --no-trunc
docker service logs SERVICE
```

Investigate specific task failures rather than repeatedly redeploying the
whole stack.

## Topology Checks

Verify that:

* all requested Engines exist
* all requested VDIs exist
* each Engine references an existing VDI
* expected overlay networks exist
* optional services match the request
* published ports do not unintentionally overlap
* services use the expected images and versions

If Engine and VDI counts differ, explicitly verify the mapping.

Do not assume one Engine per VDI unless the generator actually produces that
relationship.

## Persistent Storage

Docker Swarm scheduling changes the storage model significantly.

Named volumes using the default local Docker volume driver are local to the
node on which they exist.

Do not assume persistent database data automatically follows a service when
Swarm reschedules it to another node.

For production deployments, consider:

* constraining PostgreSQL to an appropriate persistent node
* using external PostgreSQL
* using a suitable shared or distributed storage solution

Do not delete volumes merely to solve scheduling problems.

## Updating the Stack

To update topology or versions:

1. change the relevant environment/configuration values
2. regenerate `docker-compose.yml`
3. validate with `docker stack config`
4. deploy again using the same stack name

Swarm will reconcile the existing stack toward the new definition.

Do not manually mutate individual services when the intended long-term state
belongs in the generator output unless the user explicitly wants an emergency
runtime-only change.

## Removing a Stack

Removing a stack is different from deleting persistent storage.

When explicitly requested:

```bash
docker stack rm crowler
```

Do not subsequently remove database volumes unless deletion of persistent data
was also explicitly requested.

## Troubleshooting Order

Prefer this sequence:

1. `docker stack services crowler`
2. `docker stack ps crowler --no-trunc`
3. `docker service ps SERVICE --no-trunc`
4. `docker service logs SERVICE`
5. inspect image/tag availability
6. inspect environment-variable resolution
7. inspect overlay networks
8. inspect resource availability
9. inspect storage and placement constraints

Common Swarm-specific problems include:

* worker cannot pull image
* registry authentication is unavailable to workers
* insufficient node resources
* placement constraints
* local-volume placement
* overlay network failures
* missing environment interpolation
* published-port conflicts
* Engine-to-VDI topology mismatch

Do not solve these by rebuilding CROWler images locally.

## Completion Checks

Before considering a Swarm deployment task complete:

1. Confirm stack configuration validates.
2. Confirm CROWler services use pull-based official images.
3. Confirm image versions.
4. Confirm requested topology.
5. Confirm Engine-to-VDI references.
6. Confirm overlay networks.
7. Confirm persistence assumptions.
8. Confirm environment resolution.
9. If deployed, report desired versus running replicas.
10. Report unresolved failed or rejected tasks.

Do not claim the CROWler stack is healthy solely because `docker stack deploy`
returned successfully.
