#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/.." && pwd -P)"

if [ "$(pwd -P)" != "$repo_root" ]; then
    echo "ERROR: run this script from the repository root." >&2
    exit 1
fi

usage() {
    cat <<'EOF'
Usage: bash ./scripts/validate-deployment-support.sh <target>

Targets:
  static       Shell scripts, repository structure, versions, and AI skill structure
  compose      Generate and validate Docker Compose output
  swarm        Generate and validate Docker Swarm output
  kubernetes   Validate raw Kubernetes manifests with kubeconform
  helm         Lint and render the Helm chart
  nomad        Format-check and validate the Nomad jobspec
  terraform    Format-check and validate both Terraform roots
  skills       Validate AI deployment skill structure and metadata
  all          Run every validation target
EOF
}

require_command() {
    local command_name="$1"
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "ERROR: required command was not found: $command_name" >&2
        exit 1
    fi
}

tmp_dir="$(mktemp -d)"
created_env=0
created_config=0
had_compose=0

cleanup() {
    if [ "$had_compose" -eq 1 ]; then
        cp "$tmp_dir/docker-compose.yml" docker-compose.yml
    else
        rm -f docker-compose.yml
    fi

    if [ "$created_env" -eq 1 ]; then
        rm -f .env
    fi
    if [ "$created_config" -eq 1 ]; then
        rm -f config.yaml
    fi

    rm -rf "$tmp_dir"
}
trap cleanup EXIT

if [ -f docker-compose.yml ]; then
    cp docker-compose.yml "$tmp_dir/docker-compose.yml"
    had_compose=1
fi

ensure_runtime_inputs() {
    if [ ! -f .env ]; then
        cp common/env/env_template .env
        sed -i "s/^DOCKER_POSTGRES_PASSWORD=.*/DOCKER_POSTGRES_PASSWORD='validation-only'/" .env
        sed -i "s/^DOCKER_CROWLER_DB_PASSWORD=.*/DOCKER_CROWLER_DB_PASSWORD='validation-only'/" .env
        sed -i "s/^SEL_PASSWD=.*/SEL_PASSWD='validation-only'/" .env
        created_env=1
    fi

    if [ ! -f config.yaml ]; then
        cp common/config/config.default.remote config.yaml
        created_config=1
    fi
}

validate_structure() {
    local path
    for path in \
        common/env/env_template \
        common/config/config.default \
        common/config/config.default.remote \
        docker-compose/generate-docker-compose.sh \
        docker-swarm/generate-docker-compose.sh \
        docker-swarm/README.md \
        kubernetes/base \
        helm/thecrowler/Chart.yaml \
        nomad/crowler.nomad.hcl \
        terraform/run.sh \
        .github/workflows/ci.yml \
        .github/workflows/deploy.yml \
        .github/workflows/continuous-deploy.yml \
        .github/workflows/smoke.yml \
        .agents/skills/README.md \
        user/agents \
        user/plugins \
        user/rules \
        user/support; do
        if [ ! -e "$path" ]; then
            echo "ERROR: required repository path is missing: $path" >&2
            return 1
        fi
    done
}

validate_versions() {
    local expected_crowler="2.1.0"
    local expected_vdi="4.28.1-20260819"

    grep -q "^CROWLER_VERSION=${expected_crowler}$" common/env/env_template || {
        echo "ERROR: common/env/env_template CROWler version must be ${expected_crowler}." >&2
        return 1
    }
    grep -q "^CROWLER_VDI_VERSION=${expected_vdi}$" common/env/env_template || {
        echo "ERROR: common/env/env_template VDI version must be ${expected_vdi}." >&2
        return 1
    }
    grep -q "appVersion: \"${expected_crowler}\"" helm/thecrowler/Chart.yaml || return 1
    grep -q "crowlerVersion: \"${expected_crowler}\"" helm/thecrowler/values.yaml || return 1
    grep -q "vdiVersion: \"${expected_vdi}\"" helm/thecrowler/values.yaml || return 1
    grep -q "default = \"${expected_crowler}\"" terraform/helm/variables.tf || return 1
    grep -q "default = \"${expected_vdi}\"" terraform/helm/variables.tf || return 1
    grep -q "default = \"${expected_vdi}\"" terraform/nomad/variables.tf || return 1

    if grep -Rqs 'zfpsystems/crowler-.*:2\.0\.3' kubernetes/base; then
        echo "ERROR: raw Kubernetes manifests still reference CROWler 2.0.3." >&2
        return 1
    fi
    grep -q "zfpsystems/crowler-vdi:${expected_vdi}" kubernetes/base/vdi/deployment.yaml || return 1

    if grep -Rqs '4\.28\.1-20260807' docker-compose docker-swarm nomad terraform kubernetes helm .github; then
        echo "ERROR: stale VDI fallback 4.28.1-20260807 remains in deployment definitions." >&2
        return 1
    fi

    echo "Deployment version defaults are consistent."
}

validate_skills() {
    local skill_dir skill_file skill_name declared_name
    local count=0

    for skill_dir in .agents/skills/*; do
        [ -d "$skill_dir" ] || continue
        skill_file="$skill_dir/SKILL.md"
        skill_name="$(basename "$skill_dir")"

        [ -f "$skill_file" ] || {
            echo "ERROR: AI skill is missing SKILL.md: $skill_dir" >&2
            return 1
        }
        [ "$(head -n 1 "$skill_file")" = "---" ] || {
            echo "ERROR: AI skill does not start with YAML front matter: $skill_file" >&2
            return 1
        }

        declared_name="$(sed -n 's/^name:[[:space:]]*//p' "$skill_file" | head -n 1)"
        [ "$declared_name" = "$skill_name" ] || {
            echo "ERROR: AI skill name '$declared_name' does not match directory '$skill_name'." >&2
            return 1
        }

        grep -q '^description:' "$skill_file" || return 1
        grep -q '^compatibility:' "$skill_file" || return 1
        grep -q '^[[:space:]]*project:[[:space:]]*thecrowler' "$skill_file" || return 1
        grep -q '^[[:space:]]*repository:[[:space:]]*pzaino/thecrowler-deployment-support' "$skill_file" || return 1
        count=$((count + 1))
    done

    [ "$count" -ge 8 ] || {
        echo "ERROR: expected at least 8 deployment/validation AI skills, found $count." >&2
        return 1
    }

    if grep -E '[|][[:space:]]*Planned[[:space:]]*[|]' .agents/skills/README.md | grep -Eq '(deploy|validate)-'; then
        echo "ERROR: the AI skill index still contains planned deployment/validation skills." >&2
        return 1
    fi

    echo "AI skill structure is valid ($count skills)."
}

validate_static() {
    require_command shellcheck
    validate_structure
    find . -type f -name '*.sh' -print0 | xargs -0 shellcheck
    validate_skills
    validate_versions
    echo "Static deployment validation passed."
}

validate_compose() {
    require_command docker
    ensure_runtime_inputs
    ./docker-compose/generate-docker-compose.sh -e=1 -v=1 --prom=no --pg=yes --no_jaeger
    docker compose --env-file .env -f docker-compose.yml config >/dev/null
    echo "Docker Compose generation and validation passed."
}

validate_swarm() {
    require_command docker
    ensure_runtime_inputs
    ./docker-swarm/generate-docker-compose.sh -e=2 -v=2 --prom=no --pg=yes --no_jaeger --swarm=yes

    set -a
    # shellcheck disable=SC1091
    . ./.env
    set +a

    docker stack config -c docker-compose.yml >/dev/null

    if grep -Eq 'source:[[:space:]]*\./user/' docker-compose.yml; then
        echo "ERROR: Swarm output contains node-local user-content bind mounts." >&2
        return 1
    fi

    grep -q 'crowler_config_' docker-compose.yml || {
        echo "ERROR: Swarm output does not contain versioned runtime configuration." >&2
        return 1
    }

    echo "Docker Swarm generation and validation passed."
}

validate_kubernetes() {
    require_command kubeconform
    local version
    for version in 1.27.0 1.32.0; do
        kubeconform -strict -summary -kubernetes-version "$version" kubernetes/base/
    done
    echo "Raw Kubernetes schema validation passed."
}

validate_helm() {
    require_command helm
    require_command kubeconform
    helm lint helm/thecrowler
    local version
    for version in 1.27.0 1.32.0; do
        helm template crowler helm/thecrowler --namespace crowler | \
            kubeconform -strict -summary -kubernetes-version "$version"
    done
    echo "Helm validation passed."
}

validate_nomad() {
    require_command nomad
    require_command jq
    ensure_runtime_inputs
    ./nomad/deploy.sh validate
    echo "Nomad validation passed."
}

validate_terraform() {
    require_command terraform
    require_command jq
    ensure_runtime_inputs

    local backend
    for backend in helm nomad; do
        terraform fmt -check -diff -recursive "terraform/$backend"
        terraform -chdir="terraform/$backend" init -backend=false -input=false >/dev/null
        ./terraform/run.sh "$backend" validate
    done

    echo "Terraform validation passed."
}

run_all() {
    validate_static
    validate_compose
    validate_swarm
    validate_kubernetes
    validate_helm
    validate_nomad
    validate_terraform
}

target="${1:-}"
case "$target" in
    static) validate_static ;;
    compose) validate_compose ;;
    swarm) validate_swarm ;;
    kubernetes) validate_kubernetes ;;
    helm) validate_helm ;;
    nomad) validate_nomad ;;
    terraform) validate_terraform ;;
    skills) validate_skills ;;
    all) run_all ;;
    *) usage; exit 1 ;;
esac
