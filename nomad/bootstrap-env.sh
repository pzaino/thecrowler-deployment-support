#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/.." && pwd -P)"

if [ "$(pwd -P)" != "$repo_root" ]; then
    echo "ERROR: run this script from the repository root." >&2
    echo "Run: ./nomad/bootstrap-env.sh" >&2
    exit 1
fi

for command_name in nomad jq; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "ERROR: required command '$command_name' was not found." >&2
        exit 1
    fi
done

if [ ! -f ".env" ]; then
    echo "ERROR: .env was not found in the repository root." >&2
    echo "Create it with: cp common/env/env_template .env" >&2
    exit 1
fi

# Load the same root environment used by the other deployment backends.
set -a
# shellcheck disable=SC1091
. "./.env"
set +a

namespace="${NOMAD_NAMESPACE:-default}"
variable_path="nomad/jobs/crowler/env"

# Nomad manages these values dynamically or passes them as HCL input
# variables. Do not import stale root .env values that could override service
# discovery.
declare -A excluded=(
    [CROWLER_VERSION]=1
    [CROWLER_VDI_VERSION]=1
    [DOCKER_DB_HOST]=1
    [DOCKER_DB_PORT]=1
    [DOCKER_SELENIUM_HOST]=1
    [SELENIUM_HOST]=1
    [PROMETHEUS_HOST]=1
    [SE_OTEL_EXPORTER_ENDPOINT]=1
    [INSTANCE_ID]=1
    [MICROSERVICE_NAME]=1
    [COMPOSE_PROJECT_NAME]=1
)

mapfile -t env_keys < <(
    sed -nE 's/^[[:space:]]*(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)=.*/\2/p' .env |
        awk '!seen[$0]++'
)

items='{}'

for key in "${env_keys[@]}"; do
    if [[ -n "${excluded[$key]:-}" ]]; then
        continue
    fi

    value="${!key-}"
    items="$(jq --arg key "$key" --arg value "$value" \
        '. + {($key): $value}' <<<"$items")"
done

# Nomad Variables have a 64 KiB aggregate key/value limit. Keep a conservative
# margin for JSON/spec metadata and future small additions.
items_bytes="$(printf '%s' "$items" | wc -c | tr -d '[:space:]')"
if [ "$items_bytes" -gt 60000 ]; then
    echo "ERROR: root .env content selected for Nomad is too large ($items_bytes bytes)." >&2
    echo "Nomad Variables are intended for small configuration/secrets." >&2
    exit 1
fi

payload="$(jq -n \
    --arg namespace "$namespace" \
    --arg path "$variable_path" \
    --argjson items "$items" \
    '{Namespace:$namespace, Path:$path, Items:$items}')"

printf '%s\n' "$payload" |
    nomad var put -force -in=json -

echo "Nomad environment variable synchronized:"
echo "  namespace: $namespace"
echo "  path:      $variable_path"
echo "  items:     $(jq 'length' <<<"$items")"
