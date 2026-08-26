#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/.." && pwd -P)"

if [ "$(pwd -P)" != "$repo_root" ]; then
    echo "ERROR: run this script from the repository root." >&2
    echo "Run: ./nomad/bootstrap-env.sh [--check|--apply]" >&2
    exit 1
fi

mode="${1:---apply}"
case "$mode" in
    --check|--apply) ;;
    *)
        echo "Usage: ./nomad/bootstrap-env.sh [--check|--apply]" >&2
        exit 1
        ;;
esac

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

set -a
# shellcheck disable=SC1091
. "./.env"
set +a

namespace="${NOMAD_NAMESPACE:-default}"
variable_path="nomad/jobs/crowler/env"

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
    items="$(jq --arg key "$key" --arg value "$value" '. + {($key): $value}' <<<"$items")"
done

items_bytes="$(printf '%s' "$items" | wc -c | tr -d '[:space:]')"
if [ "$items_bytes" -gt 60000 ]; then
    echo "ERROR: root .env content selected for Nomad is too large ($items_bytes bytes)." >&2
    echo "Nomad Variables are intended for small configuration/secrets." >&2
    exit 1
fi

if [ "$mode" = "--check" ]; then
    desired="$(jq -S -c . <<<"$items")"
    current='{}'

    if current_payload="$(nomad var get -namespace "$namespace" -out=json "$variable_path" 2>/dev/null)"; then
        current="$(jq -S -c '.Items // {}' <<<"$current_payload")"
    fi

    if [ "$desired" = "$current" ]; then
        echo "Nomad environment Variable is already in sync:"
        echo "  namespace: $namespace"
        echo "  path:      $variable_path"
        exit 0
    fi

    echo "Nomad environment Variable would change (read-only check):"
    echo "  namespace: $namespace"
    echo "  path:      $variable_path"
    jq -n \
        --argjson current "$current" \
        --argjson desired "$desired" \
        '{
          added:   (($desired | keys) - ($current | keys)),
          removed: (($current | keys) - ($desired | keys)),
          changed: [($desired | keys[]) as $key | select(($current | has($key)) and ($current[$key] != $desired[$key])) | $key]
        }'
    exit 0
fi

payload="$(jq -n \
    --arg namespace "$namespace" \
    --arg path "$variable_path" \
    --argjson items "$items" \
    '{Namespace:$namespace, Path:$path, Items:$items}')"

printf '%s\n' "$payload" | nomad var put -force -in=json -

echo "Nomad environment Variable synchronized:"
echo "  namespace: $namespace"
echo "  path:      $variable_path"
echo "  items:     $(jq 'length' <<<"$items")"
