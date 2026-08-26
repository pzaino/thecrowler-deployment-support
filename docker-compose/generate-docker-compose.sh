#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

for arg in "$@"; do
    case "$arg" in
        --swarm=*)
            echo "ERROR: --swarm is no longer supported by the Docker Compose generator." >&2
            echo "Use ./docker-swarm/generate-docker-compose.sh for Docker Swarm deployments." >&2
            exit 2
            ;;
    esac
done

exec "$script_dir/generate-docker-compose.impl.sh" "$@"
