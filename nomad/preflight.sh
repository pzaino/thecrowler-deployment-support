#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/.." && pwd -P)"

if [ "$(pwd -P)" != "$repo_root" ]; then
    echo "ERROR: run Nomad deployment commands from the repository root." >&2
    exit 1
fi

missing=0

for path in \
    ".env" \
    "config.yaml" \
    "user/agents" \
    "user/plugins" \
    "user/rules" \
    "user/support" \
    "nomad/crowler.nomad.hcl"; do
    if [ ! -e "$path" ]; then
        echo "ERROR: required repository-root path is missing: $path" >&2
        missing=1
    fi
done

if [ "$missing" -ne 0 ]; then
    exit 1
fi

if ! command -v nomad >/dev/null 2>&1; then
    echo "ERROR: Nomad CLI was not found." >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq was not found." >&2
    exit 1
fi

# The current CROWler local configuration template historically used a literal
# localhost for VDI. A Nomad Engine receives its selected VDI host through the
# SELENIUM_HOST environment variable, so local/remote effective configuration
# must consume that variable.
if grep -Eq '^[[:space:]]*vdi:[[:space:]]*$' config.yaml; then
    if ! grep -Fq '${SELENIUM_HOST}' config.yaml; then
        echo "ERROR: config.yaml contains a local VDI section but does not reference \${SELENIUM_HOST}." >&2
        echo >&2
        echo "For Nomad local VDI discovery, set the VDI host to:" >&2
        echo '    host: ${SELENIUM_HOST}' >&2
        echo >&2
        echo "See: nomad/config-runtime-contract.md" >&2
        exit 1
    fi
fi

echo "Nomad preflight checks passed."
