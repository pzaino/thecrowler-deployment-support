#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/.." && pwd -P)"

if [ "$(pwd -P)" != "$repo_root" ]; then
    echo "ERROR: run this script from the repository root." >&2
    echo "Run: ./nomad/deploy.sh <command>" >&2
    exit 1
fi

usage() {
    cat <<'EOF'
Usage:
  ./nomad/deploy.sh validate
  ./nomad/deploy.sh env-sync
  ./nomad/deploy.sh volume-create
  ./nomad/deploy.sh plan
  ./nomad/deploy.sh run
  ./nomad/deploy.sh status
  ./nomad/deploy.sh stop
  ./nomad/deploy.sh allocations

Commands:
  validate       Local/root checks plus `nomad job validate`
  env-sync       Copy selected root .env values into Nomad Variables
  volume-create  Create the bundled PostgreSQL dynamic host volume
  plan           Sync .env, then show Nomad scheduling/update plan
  run            Sync .env, then submit/update the CROWler job
  status         Show the CROWler Nomad job
  stop           Stop the CROWler job without purging it
  allocations    List CROWler allocations

Optional non-secret overrides:
  cp nomad/values.example.hcl nomad/values.hcl
EOF
}

if [ "$#" -ne 1 ]; then
    usage
    exit 1
fi

command_name="$1"

if ! command -v nomad >/dev/null 2>&1; then
    echo "ERROR: Nomad CLI was not found." >&2
    exit 1
fi

if [ ! -f ".env" ]; then
    echo "ERROR: root .env was not found." >&2
    exit 1
fi

set -a
# shellcheck disable=SC1091
. "./.env"
set +a

# Keep image versions consistent with the other deployment backends.
export NOMAD_VAR_crowler_version="${CROWLER_VERSION:-latest}"
export NOMAD_VAR_vdi_version="${CROWLER_VDI_VERSION:-4.28.1-20260819}"

var_args=()
if [ -f "nomad/values.hcl" ]; then
    var_args+=("-var-file=nomad/values.hcl")
fi

job_file="nomad/crowler.nomad.hcl"

case "$command_name" in
    validate)
        ./nomad/preflight.sh
        nomad fmt -check "$job_file"
        if [ -f "nomad/values.hcl" ]; then
            nomad fmt -check "nomad/values.hcl"
        fi
        nomad job validate "${var_args[@]}" "$job_file"
        ;;

    env-sync)
        ./nomad/preflight.sh
        ./nomad/bootstrap-env.sh
        ;;

    volume-create)
        ./nomad/preflight.sh
        nomad volume create "nomad/volumes/crowler-db-data.hcl"
        ;;

    plan)
        ./nomad/preflight.sh
        ./nomad/bootstrap-env.sh
        nomad job plan "${var_args[@]}" "$job_file"
        ;;

    run)
        ./nomad/preflight.sh
        ./nomad/bootstrap-env.sh
        nomad job run "${var_args[@]}" "$job_file"
        ;;

    status)
        nomad job status crowler
        ;;

    stop)
        nomad job stop crowler
        ;;

    allocations)
        nomad job allocs crowler
        ;;

    *)
        usage
        exit 1
        ;;
esac
