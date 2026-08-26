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
  ./nomad/deploy.sh env-check
  ./nomad/deploy.sh env-sync
  ./nomad/deploy.sh volume-create
  ./nomad/deploy.sh volume-ensure
  ./nomad/deploy.sh plan
  ./nomad/deploy.sh run
  ./nomad/deploy.sh status
  ./nomad/deploy.sh stop
  ./nomad/deploy.sh allocations

Commands:
  validate       Local/root checks plus `nomad job validate`
  env-check      Compare root .env with the Nomad Variable without modifying it
  env-sync       Copy selected root .env values into Nomad Variables
  volume-create  Create the bundled PostgreSQL dynamic host volume
  volume-ensure  Create the bundled PostgreSQL volume only when it does not exist
  plan           Read-only environment drift check plus Nomad scheduling/update plan
  run            Ensure optional bundled DB storage, sync .env, then submit/update the job
  status         Show the CROWler Nomad job
  stop           Stop the CROWler job without purging it
  allocations    List CROWler allocations

Optional non-secret overrides:
  cp nomad/values.example.hcl nomad/values.hcl

Environment controls:
  NOMAD_NAMESPACE                 Namespace for the job, Variable, and host volume (default: default)
  NOMAD_MANAGE_DATABASE_VOLUME    yes/no; ensure bundled PostgreSQL volume on run (default: yes)
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

export NOMAD_NAMESPACE="${NOMAD_NAMESPACE:-default}"
export NOMAD_VAR_namespace="$NOMAD_NAMESPACE"

# Keep image versions consistent with the other deployment backends.
export NOMAD_VAR_crowler_version="${CROWLER_VERSION:-2.1.0}"
export NOMAD_VAR_vdi_version="${CROWLER_VDI_VERSION:-4.28.1-20260819}"

manage_database_volume="${NOMAD_MANAGE_DATABASE_VOLUME:-yes}"
case "$manage_database_volume" in
    yes|no) ;;
    *)
        echo "ERROR: NOMAD_MANAGE_DATABASE_VOLUME must be 'yes' or 'no'." >&2
        exit 1
        ;;
esac

var_args=()
if [ -f "nomad/values.hcl" ]; then
    var_args+=("-var-file=nomad/values.hcl")
fi

job_file="nomad/crowler.nomad.hcl"
volume_file="nomad/volumes/crowler-db-data.hcl"
volume_name="crowler-db-data"

volume_exists() {
    nomad volume status -type=host -namespace="$NOMAD_NAMESPACE" 2>/dev/null |
        awk -v expected="$volume_name" 'NR > 1 && $2 == expected { found=1 } END { exit found ? 0 : 1 }'
}

ensure_database_volume() {
    if volume_exists; then
        echo "Nomad dynamic host volume '$volume_name' already exists in namespace '$NOMAD_NAMESPACE'."
        return 0
    fi

    echo "Creating Nomad dynamic host volume '$volume_name' in namespace '$NOMAD_NAMESPACE'."
    nomad volume create -namespace="$NOMAD_NAMESPACE" "$volume_file"
}

case "$command_name" in
    validate)
        ./nomad/preflight.sh
        nomad fmt -check "$job_file"
        if [ -f "nomad/values.hcl" ]; then
            nomad fmt -check "nomad/values.hcl"
        fi
        nomad job validate "${var_args[@]}" "$job_file"
        ;;

    env-check)
        ./nomad/preflight.sh
        ./nomad/bootstrap-env.sh --check
        ;;

    env-sync)
        ./nomad/preflight.sh
        ./nomad/bootstrap-env.sh --apply
        ;;

    volume-create)
        ./nomad/preflight.sh
        nomad volume create -namespace="$NOMAD_NAMESPACE" "$volume_file"
        ;;

    volume-ensure)
        ./nomad/preflight.sh
        ensure_database_volume
        ;;

    plan)
        ./nomad/preflight.sh
        ./nomad/bootstrap-env.sh --check
        nomad job plan "${var_args[@]}" "$job_file"
        ;;

    run)
        ./nomad/preflight.sh
        if [ "$manage_database_volume" = "yes" ]; then
            ensure_database_volume
        fi
        ./nomad/bootstrap-env.sh --apply
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
