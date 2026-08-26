#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/.." && pwd -P)"

if [ "$(pwd -P)" != "$repo_root" ]; then
    echo "ERROR: run Terraform deployment commands from the repository root." >&2
    echo "Run: ./terraform/run.sh <nomad|helm> <terraform-command> [args...]" >&2
    exit 1
fi

usage() {
    cat <<'EOF'
Usage:
  ./terraform/run.sh nomad init
  ./terraform/run.sh nomad validate
  ./terraform/run.sh nomad plan
  ./terraform/run.sh nomad apply
  ./terraform/run.sh nomad output

  ./terraform/run.sh helm init
  ./terraform/run.sh helm validate
  ./terraform/run.sh helm plan
  ./terraform/run.sh helm apply
  ./terraform/run.sh helm output

Additional Terraform arguments are passed through unchanged.

Examples:
  ./terraform/run.sh nomad plan -out=tfplan
  ./terraform/run.sh nomad apply tfplan
  ./terraform/run.sh helm plan -var-file=terraform.tfvars
EOF
}

if [ "$#" -lt 2 ]; then
    usage
    exit 1
fi

backend="$1"
shift

case "$backend" in
    nomad|helm) ;;
    *)
        echo "ERROR: backend must be 'nomad' or 'helm'." >&2
        usage
        exit 1
        ;;
esac

for command_name in terraform jq cksum; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "ERROR: required command '$command_name' was not found." >&2
        exit 1
    fi
done

for required_path in \
    ".env" \
    "config.yaml" \
    "user/agents" \
    "user/plugins" \
    "user/rules" \
    "user/support"; do
    if [ ! -e "$required_path" ]; then
        echo "ERROR: required repository-root path is missing: $required_path" >&2
        exit 1
    fi
done

set -a
# shellcheck disable=SC1091
. "./.env"
set +a

export TF_VAR_crowler_version="${CROWLER_VERSION:-latest}"
export TF_VAR_vdi_version="${CROWLER_VDI_VERSION:-4.28.1-20260819}"

# Root .env values that are generated dynamically by deployment backends must
# not override provider/service-discovery values.
excluded_keys='
CROWLER_VERSION
CROWLER_VDI_VERSION
DOCKER_DB_HOST
DOCKER_DB_PORT
DOCKER_SELENIUM_HOST
SELENIUM_HOST
PROMETHEUS_HOST
SE_OTEL_EXPORTER_ENDPOINT
INSTANCE_ID
MICROSERVICE_NAME
COMPOSE_PROJECT_NAME
'

is_excluded() {
    key="$1"
    printf '%s\n' "$excluded_keys" | grep -Fxq "$key"
}

env_json='{}'

while IFS= read -r key; do
    [ -n "$key" ] || continue

    if is_excluded "$key"; then
        continue
    fi

    value="${!key-}"
    env_json="$(
        jq --arg key "$key" --arg value "$value" \
            '. + {($key): $value}' <<<"$env_json"
    )"
done < <(
    sed -nE 's/^[[:space:]]*(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)=.*/\2/p' .env |
        awk '!seen[$0]++'
)

for required_key in \
    DOCKER_POSTGRES_PASSWORD \
    DOCKER_CROWLER_DB_USER \
    DOCKER_CROWLER_DB_PASSWORD \
    SEL_PASSWD; do
    if ! jq -e --arg key "$required_key" 'has($key)' <<<"$env_json" >/dev/null; then
        echo "ERROR: root .env does not define required key: $required_key" >&2
        exit 1
    fi
done

# Write-only provider attributes require a non-secret revision marker.
# POSIX cksum gives a stable numeric value for unchanged content.
env_revision="$(printf '%s' "$env_json" | cksum | awk '{print $1}')"
if [ "$env_revision" -eq 0 ]; then
    env_revision=1
fi

case "$backend" in
    nomad)
        export TF_VAR_nomad_env_json="$env_json"
        export TF_VAR_nomad_env_revision="$env_revision"
        ;;
    helm)
        export TF_VAR_kubernetes_secret_json="$env_json"
        export TF_VAR_kubernetes_secret_revision="$env_revision"
        ;;
esac

exec terraform -chdir="terraform/$backend" "$@"
