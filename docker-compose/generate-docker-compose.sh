#!/bin/bash

# The CROWler Docker Compose / Docker Swarm deployment generator.
#
# Run from the deployment workspace, normally the repository root:
#
#   ./docker-compose/generate-docker-compose.sh ...
#
# The default deployment inputs are:
#   .env
#   config.yaml
#
# The generated output is:
#   docker-compose.yml

engine_count=""
vdi_count=""
prometheus=""
postgres=""
cpu_limit=""
cpu_limit_engine=""
cpu_limit_vdi=""
cpu_limit_mng=""
cpu_limit_tlm=""
no_api=0
no_events=0
no_jaeger=0
mem_limit_vdi_pct=""
mem_limit_eng_pct=""
mem_limit_mng_pct=""
mem_limit_tlm_pct=""
use_swarm="no"
env_file=".env"
config_file="${CROWLER_CONFIG_FILE:-config.yaml}"

cmd_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --engine_count=<number>     Number of crowler-engine instances"
    echo "  --engine=<number>           Number of crowler-engine instances"
    echo "  -e=<number>                 Number of crowler-engine instances"
    echo "  --vdi_count=<number>        Number of crowler-vdi instances"
    echo "  --vdi=<number>              Number of crowler-vdi instances"
    echo "  -v=<number>                 Number of crowler-vdi instances"
    echo "  --prometheus=<yes/no>       Include Prometheus PushGateway"
    echo "  --prom=<yes/no>             Include Prometheus PushGateway"
    echo "  --postgres=<yes/no>         Include PostgreSQL database"
    echo "  --pg=<yes/no>               Include PostgreSQL database"
    echo "  --cpu_limit=<number>        CPU limit for all services"
    echo "  --cpu_limit_engine=<number> CPU limit for crowler-engine instances"
    echo "  --cpu_limit_vdi=<number>    CPU limit for crowler-vdi instances"
    echo "  --cpu_limit_mng=<number>    CPU limit for crowler-api and crowler-events"
    echo "  --cpu_limit_tlm=<number>    CPU limit for Jaeger and Pushgateway"
    echo "  --no_api                    Do not include crowler-api"
    echo "  --no_events                 Do not include crowler-events"
    echo "  --no_jaeger                 Do not include Jaeger"
    echo "  --mem_limit_vdi=<number>    Memory limit for crowler-vdi instances in %"
    echo "  --mem_limit_engine=<number> Memory limit for crowler-engine instances in %"
    echo "  --mem_limit_mng=<number>    Memory limit for crowler-api and crowler-events in %"
    echo "  --mem_limit_tlm=<number>    Memory limit for Jaeger and Pushgateway in %"
    echo "  --swarm=<yes/no>            Generate Docker Swarm-compatible output"
    echo "  --env-file=<path>           Environment file (default: .env)"
    echo "  --config=<path>             CROWler runtime config (default: config.yaml)"
    echo "  -h, --help                  Show this help"
}

read_integer_input() {
    local prompt="$1"
    local varname="$2"
    local value
    while :; do
        read -r -p "$prompt" value
        if [[ "$value" =~ ^[0-9]+$ ]]; then
            printf -v "$varname" '%s' "$value"
            break
        fi
        echo "Invalid input. Please provide a non-negative integer."
    done
}

read_yes_no_input() {
    local prompt="$1"
    local varname="$2"
    local value
    while :; do
        read -r -p "$prompt (yes/no): " value
        value=$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]' | xargs)
        if [[ "$value" == "yes" || "$value" == "no" ]]; then
            printf -v "$varname" '%s' "$value"
            break
        fi
        echo "Invalid input. Please provide 'yes' or 'no'."
    done
}

validate_non_negative_integer() {
    local name="$1"
    local value="$2"
    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        echo "ERROR: $name must be a non-negative integer."
        exit 1
    fi
}

validate_yes_no() {
    local name="$1"
    local value="$2"
    if [[ "$value" != "yes" && "$value" != "no" ]]; then
        echo "ERROR: $name must be 'yes' or 'no'."
        exit 1
    fi
}

detect_cpu_count() {
    if command -v nproc >/dev/null 2>&1; then
        nproc --all
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        sysctl -n hw.logicalcpu
    elif command -v getconf >/dev/null 2>&1; then
        getconf _NPROCESSORS_ONLN
    else
        echo "1"
    fi
}

detect_total_memory_mb() {
    if command -v free >/dev/null 2>&1; then
        free -m | awk '/^Mem:/ { print $2 }'
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        sysctl -n hw.memsize | awk '{print int($1 / 1024 / 1024)}'
    else
        echo "2048"
    fi
}

to_mem_unit() {
    local mb="$1"
    if [ "$mb" -ge 1024 ]; then
        echo "$((mb / 1024))g"
    else
        echo "${mb}m"
    fi
}

emit_runtime() {
    local indent="$1"
    local cpus="$2"
    local memory="$3"

    if [ "$use_swarm" == "yes" ]; then
        echo "${indent}deploy:"
        echo "${indent}  resources:"
        echo "${indent}    limits:"
        echo "${indent}      cpus: \"$cpus\""
        echo "${indent}      memory: \"$memory\""
        echo "${indent}  restart_policy:"
        echo "${indent}    condition: any"
    else
        echo "${indent}cpus: \"$cpus\""
        echo "${indent}mem_limit: \"$memory\""
        echo "${indent}restart: unless-stopped"
    fi
}

emit_container_name() {
    local indent="$1"
    local name="$2"
    if [ "$use_swarm" != "yes" ]; then
        echo "${indent}container_name: \"$name\""
    fi
}

emit_pull_policy() {
    local indent="$1"
    if [ "$use_swarm" != "yes" ]; then
        echo "${indent}pull_policy: always"
    fi
}

for arg in "$@"; do
    case "$arg" in
        -h|--help)
            cmd_usage
            exit 0
            ;;
        --engine_count=*|--engine=*)
            engine_count="${arg#*=}"
            ;;
        -e=*)
            engine_count="${arg#-e=}"
            ;;
        --vdi_count=*|--vdi=*)
            vdi_count="${arg#*=}"
            ;;
        -v=*)
            vdi_count="${arg#-v=}"
            ;;
        --prometheus=*|--prom=*)
            prometheus="${arg#*=}"
            ;;
        --postgres=*|--pg=*)
            postgres="${arg#*=}"
            ;;
        --cpu_limit=*|--cpu=*|--cpu-limit=*)
            cpu_limit="${arg#*=}"
            ;;
        --cpu_limit_engine=*)
            cpu_limit_engine="${arg#*=}"
            ;;
        --cpu_limit_vdi=*)
            cpu_limit_vdi="${arg#*=}"
            ;;
        --cpu_limit_mng=*)
            cpu_limit_mng="${arg#*=}"
            ;;
        --cpu_limit_tlm=*)
            cpu_limit_tlm="${arg#*=}"
            ;;
        --no_api)
            no_api=1
            ;;
        --no_events)
            no_events=1
            ;;
        --no_jaeger)
            no_jaeger=1
            ;;
        --mem_limit_vdi=*)
            mem_limit_vdi_pct="${arg#*=}"
            ;;
        --mem_limit_engine=*)
            mem_limit_eng_pct="${arg#*=}"
            ;;
        --mem_limit_mng=*)
            mem_limit_mng_pct="${arg#*=}"
            ;;
        --mem_limit_tlm=*)
            mem_limit_tlm_pct="${arg#*=}"
            ;;
        --swarm=*)
            use_swarm="${arg#*=}"
            ;;
        --env-file=*)
            env_file="${arg#*=}"
            ;;
        --config=*)
            config_file="${arg#*=}"
            ;;
        *)
            echo "ERROR: Unknown option: $arg"
            echo
            cmd_usage
            exit 1
            ;;
    esac
done

if [ -z "$engine_count" ]; then
    read_integer_input "Enter the number of crowler-engine instances: " engine_count
fi
if [ -z "$vdi_count" ]; then
    read_integer_input "Enter the number of crowler-vdi instances: " vdi_count
fi
if [ -z "$prometheus" ]; then
    read_yes_no_input "Do you want to include the Prometheus PushGateway?" prometheus
fi
if [ -z "$postgres" ]; then
    read_yes_no_input "Do you want to include the PostgreSQL database?" postgres
fi

validate_non_negative_integer "engine_count" "$engine_count"
validate_non_negative_integer "vdi_count" "$vdi_count"
validate_yes_no "prometheus" "$prometheus"
validate_yes_no "postgres" "$postgres"
validate_yes_no "swarm" "$use_swarm"

for pct in "$mem_limit_vdi_pct" "$mem_limit_eng_pct" "$mem_limit_mng_pct" "$mem_limit_tlm_pct"; do
    if [ -n "$pct" ]; then
        if ! [[ "$pct" =~ ^[0-9]+$ ]] || [ "$pct" -lt 1 ] || [ "$pct" -gt 100 ]; then
            echo "ERROR: Memory limit percentages must be integers between 1 and 100."
            exit 1
        fi
    fi
done

if [ ! -f "$env_file" ]; then
    echo "ERROR: Environment file '$env_file' was not found."
    echo "Create one with:"
    echo "  cp common/env/env_template .env"
    echo "or pass --env-file=<path>."
    exit 1
fi

needs_crowler_config=0
if [ "$engine_count" != "0" ] || [ "$no_api" == "0" ] || [ "$no_events" == "0" ]; then
    needs_crowler_config=1
fi

if [ "$needs_crowler_config" == "1" ] && [ ! -f "$config_file" ]; then
    echo "ERROR: CROWler runtime configuration '$config_file' was not found."
    echo "Create one from either:"
    echo "  cp common/config/config.default config.yaml"
    echo "or:"
    echo "  cp common/config/config.default.remote config.yaml"
    echo "You may also pass --config=<path>."
    exit 1
fi

total_cpus=$(detect_cpu_count)
cpu_limit=${cpu_limit:-$total_cpus}
cpu_limit_engine=${cpu_limit_engine:-$cpu_limit}
cpu_limit_vdi=${cpu_limit_vdi:-$cpu_limit}
cpu_limit_mng=${cpu_limit_mng:-$cpu_limit}
cpu_limit_tlm=${cpu_limit_tlm:-$cpu_limit}

total_memory_mb=$(detect_total_memory_mb)

if [ -z "$mem_limit_vdi_pct" ]; then
    mem_limit_vdi_pct=$((total_memory_mb * 80 / 100))
else
    mem_limit_vdi_pct=$((total_memory_mb * mem_limit_vdi_pct / 100))
fi

if [ -z "$mem_limit_eng_pct" ]; then
    mem_limit_eng_pct=$((total_memory_mb * 80 / 100))
else
    mem_limit_eng_pct=$((total_memory_mb * mem_limit_eng_pct / 100))
fi

if [ -z "$mem_limit_mng_pct" ]; then
    mem_limit_mng_pct=$((total_memory_mb * 80 / 100))
else
    mem_limit_mng_pct=$((total_memory_mb * mem_limit_mng_pct / 100))
fi

if [ -z "$mem_limit_tlm_pct" ]; then
    mem_limit_tlm_pct=$((total_memory_mb * 80 / 100))
else
    mem_limit_tlm_pct=$((total_memory_mb * mem_limit_tlm_pct / 100))
fi

mem_limit_vdi_pct=$(to_mem_unit "$mem_limit_vdi_pct")
mem_limit_eng_pct=$(to_mem_unit "$mem_limit_eng_pct")
mem_limit_mng_pct=$(to_mem_unit "$mem_limit_mng_pct")
mem_limit_tlm_pct=$(to_mem_unit "$mem_limit_tlm_pct")

if [ "$use_swarm" == "yes" ]; then
    net_driver="overlay"
else
    net_driver="bridge"
fi

cat <<'EOF' > docker-compose.yml
---
services:
EOF

if [ "$no_api" == "0" ]; then
    {
        echo
        echo "  crowler-api:"
        emit_container_name "    " "crowler-api"
        emit_runtime "    " "${cpu_limit_mng:-1.0}" "${mem_limit_mng_pct:-2g}"
        cat <<EOF
    env_file:
      - "$env_file"
    environment:
      - COMPOSE_PROJECT_NAME=crowler
      - INSTANCE_ID=\${INSTANCE_ID:-1}
      - POSTGRES_DB=\${DOCKER_POSTGRES_DB_NAME:-SitesIndex}
      - CROWLER_DB_USER=\${DOCKER_CROWLER_DB_USER:-crowler}
      - CROWLER_DB_PASSWORD=\${DOCKER_CROWLER_DB_PASSWORD}
      - POSTGRES_DB_HOST=\${DOCKER_DB_HOST:-crowler-db}
      - POSTGRES_DB_PORT=\${DOCKER_DB_PORT:-5432}
      - POSTGRES_SSL_MODE=\${DOCKER_POSTGRES_SSL_MODE:-disable}
      - TZ=\${VDI_TZ:-UTC}
      - MICROSERVICE_NAME=crowler-api
    image: zfpsystems/crowler-api:\${CROWLER_VERSION:-latest}
EOF
        emit_pull_policy "    "
        cat <<'EOF'
    stdin_open: true
    tty: true
    ports:
      - "8080:8080"
    networks:
      - crowler-net
    volumes:
      - api_data:/app/data
      - ./user/agents:/app/user/agents:ro
      - ./user/plugins:/app/user/plugins:ro
      - ./user/rules:/app/user/rules:ro
      - ./user/support:/app/user/support:ro
    configs:
      - source: crowler_config
        target: /app/config.yaml
    user: apiuser
    read_only: true
    healthcheck:
      test: ["CMD-SHELL", "./healthCheck -service api"]
      interval: 10s
      timeout: 5s
      retries: 5
EOF
    } >> docker-compose.yml
fi

if [ "$no_events" == "0" ]; then
    {
        echo
        echo "  crowler-events:"
        emit_container_name "    " "crowler-events"
        emit_runtime "    " "${cpu_limit_mng:-1.0}" "${mem_limit_mng_pct:-2g}"
        cat <<EOF
    env_file:
      - "$env_file"
    environment:
      - COMPOSE_PROJECT_NAME=crowler
      - INSTANCE_ID=\${INSTANCE_ID:-1}
      - POSTGRES_DB=\${DOCKER_POSTGRES_DB_NAME:-SitesIndex}
      - CROWLER_DB_USER=\${DOCKER_CROWLER_DB_USER:-crowler}
      - CROWLER_DB_PASSWORD=\${DOCKER_CROWLER_DB_PASSWORD}
      - POSTGRES_DB_HOST=\${DOCKER_DB_HOST:-crowler-db}
      - POSTGRES_DB_PORT=\${DOCKER_DB_PORT:-5432}
      - POSTGRES_SSL_MODE=\${DOCKER_POSTGRES_SSL_MODE:-disable}
      - TZ=\${VDI_TZ:-UTC}
      - MICROSERVICE_NAME=crowler-events
    image: zfpsystems/crowler-events:\${CROWLER_VERSION:-latest}
EOF
        emit_pull_policy "    "
        cat <<'EOF'
    stdin_open: true
    tty: true
    ports:
      - "8082:8082"
    networks:
      - crowler-net
    volumes:
      - events_data:/app/data
      - ./user/agents:/app/user/agents:ro
      - ./user/plugins:/app/user/plugins:ro
      - ./user/rules:/app/user/rules:ro
      - ./user/support:/app/user/support:ro
    configs:
      - source: crowler_config
        target: /app/config.yaml
    user: eventsuser
    read_only: true
    healthcheck:
      test: ["CMD-SHELL", "./healthCheck -service events"]
      interval: 10s
      timeout: 5s
      retries: 5
EOF
    } >> docker-compose.yml
fi

if [ "$postgres" == "yes" ]; then
    {
        echo
        echo "  crowler-db:"
        emit_container_name "    " "crowler-db"
        emit_runtime "    " "${cpu_limit_mng:-1.0}" "${mem_limit_mng_pct:-3g}"
        cat <<EOF
    image: zfpsystems/crowler-db:\${CROWLER_VERSION:-latest}
EOF
        emit_pull_policy "    "
        cat <<EOF
    ports:
      - "5432:5432"
    env_file:
      - "$env_file"
    environment:
      - COMPOSE_PROJECT_NAME=crowler
      - POSTGRES_DB=\${DOCKER_POSTGRES_DB_NAME:-SitesIndex}
      - POSTGRES_USER=\${DOCKER_POSTGRES_USER:-postgres}
      - POSTGRES_PASSWORD=\${DOCKER_POSTGRES_PASSWORD}
      - CROWLER_DB_USER=\${DOCKER_CROWLER_DB_USER:-crowler}
      - CROWLER_DB_PASSWORD=\${DOCKER_CROWLER_DB_PASSWORD}
      - PROXY_SERVICE=\${VDI_PROXY_SERVICE:-}
      - TZ=\${VDI_TZ:-UTC}
      - MICROSERVICE_NAME=crowler-db
    command: ["postgres", "-c", "timezone=\${VDI_TZ:-UTC}"]
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - crowler-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \$\${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
EOF
    } >> docker-compose.yml
fi

if [ "$engine_count" != "0" ]; then
    for i in $(seq 1 "$engine_count"); do
        ENGINE_NETWORKS=""
        for j in $(seq 1 "$vdi_count"); do
            ENGINE_NETWORKS="${ENGINE_NETWORKS}      - crowler-vdi-$j"$'\n'
        done

        if [ "$vdi_count" -gt 0 ]; then
            vdi_index=$(( ((i - 1) % vdi_count) + 1 ))
            selenium_default="crowler-vdi-$vdi_index"
        else
            selenium_default=""
        fi

        {
            echo
            echo "  crowler-engine-$i:"
            emit_container_name "    " "crowler-engine-$i"
            emit_runtime "    " "${cpu_limit_engine:-1.0}" "${mem_limit_eng_pct:-2g}"
            cat <<EOF
    env_file:
      - "$env_file"
    environment:
      - COMPOSE_PROJECT_NAME=crowler
      - INSTANCE_ID=$i
      - SELENIUM_HOST=\${DOCKER_SELENIUM_HOST:-$selenium_default}
      - POSTGRES_DB=\${DOCKER_POSTGRES_DB_NAME:-SitesIndex}
      - CROWLER_DB_USER=\${DOCKER_CROWLER_DB_USER:-crowler}
      - CROWLER_DB_PASSWORD=\${DOCKER_CROWLER_DB_PASSWORD}
      - POSTGRES_DB_HOST=\${DOCKER_DB_HOST:-crowler-db}
      - POSTGRES_DB_PORT=\${DOCKER_DB_PORT:-5432}
      - POSTGRES_SSL_MODE=\${DOCKER_POSTGRES_SSL_MODE:-disable}
      - CROWLER_MAIL_CONNECTOR_HOST=\${CROWLER_MAIL_CONNECTOR_HOST:-}
      - CROWLER_MAIL_CONNECTOR_PORT=\${CROWLER_MAIL_CONNECTOR_PORT:-}
      - CROWLER_MAIL_CONNECTOR_USERNAME=\${CROWLER_MAIL_CONNECTOR_USERNAME:-}
      - CROWLER_MAIL_CREDENTIAL_REF=\${CROWLER_MAIL_CREDENTIAL_REF:-}
      - CROWLER_MAIL_PROVIDER_ACCOUNT_ID=\${CROWLER_MAIL_PROVIDER_ACCOUNT_ID:-}
      - CROWLER_MAIL_PROVIDER_PROJECT_ID=\${CROWLER_MAIL_PROVIDER_PROJECT_ID:-}
      - CROWLER_MAIL_PROVIDER_TENANT_ID=\${CROWLER_MAIL_PROVIDER_TENANT_ID:-}
      - CROWLER_MAIL_PROVIDER_CLIENT_ID=\${CROWLER_MAIL_PROVIDER_CLIENT_ID:-}
      - CROWLER_MAIL_PROVIDER_SUBSCRIPTION_ID=\${CROWLER_MAIL_PROVIDER_SUBSCRIPTION_ID:-}
      - CROWLER_MAIL_LISTENER_ENABLED=\${CROWLER_MAIL_LISTENER_ENABLED:-false}
      - CROWLER_MAIL_LISTENER_BUFFER_SIZE=\${CROWLER_MAIL_LISTENER_BUFFER_SIZE:-128}
      - CROWLER_MAIL_LISTENER_COALESCE_WINDOW=\${CROWLER_MAIL_LISTENER_COALESCE_WINDOW:-1s}
      - CROWLER_MAIL_LISTENER_RECONNECT_BACKOFF=\${CROWLER_MAIL_LISTENER_RECONNECT_BACKOFF:-5s}
      - CROWLER_MAIL_LISTENER_MAX_RECONNECT_BACKOFF=\${CROWLER_MAIL_LISTENER_MAX_RECONNECT_BACKOFF:-1m}
      - CROWLER_MAIL_LISTENER_IDLE_REISSUE_INTERVAL=\${CROWLER_MAIL_LISTENER_IDLE_REISSUE_INTERVAL:-25m}
      - TZ=\${VDI_TZ:-UTC}
      - MICROSERVICE_NAME=crowler-engine-$i
    image: zfpsystems/crowler-engine:\${CROWLER_VERSION:-latest}
EOF
            emit_pull_policy "    "
            cat <<'EOF'
    networks:
      - crowler-net
EOF
            if [ -n "$ENGINE_NETWORKS" ]; then
                printf '%s' "$ENGINE_NETWORKS"
            fi
            cat <<'EOF'
    cap_add:
      - NET_ADMIN
      - NET_RAW
    stdin_open: true
    tty: true
    volumes:
      - engine_data:/app/data
      - ./user/agents:/app/user/agents:ro
      - ./user/plugins:/app/user/plugins:ro
      - ./user/rules:/app/user/rules:ro
      - ./user/support:/app/user/support:ro
    configs:
      - source: crowler_config
        target: /app/config.yaml
    user: crowler
    healthcheck:
      test: ["CMD-SHELL", "./healthCheck -service crowler"]
      interval: 10s
      timeout: 5s
      retries: 5
EOF
        } >> docker-compose.yml
    done
fi

if [ "$vdi_count" != "0" ] && [ "$no_jaeger" == "0" ]; then
    {
        echo
        echo "  crowler-jaeger:"
        emit_container_name "    " "crowler-jaeger"
        emit_runtime "    " "${cpu_limit_tlm:-1.0}" "${mem_limit_tlm_pct:-2g}"
        cat <<EOF
    image: jaegertracing/all-in-one:1.54
    environment:
      - COLLECTOR_ZIPKIN_HTTP_PORT=9411
      - JAEGER_AGENT_HOST=crowler-jaeger
      - JAEGER_SERVICE_NAME=crowler-jaeger
      - JAEGER_SAMPLER_TYPE=const
      - JAEGER_SAMPLER_PARAM=1
      - TZ=\${VDI_TZ:-UTC}
      - MICROSERVICE_NAME=crowler-jaeger
    ports:
      - "16686:16686"
      - "4317:4317"
    networks:
      - crowler-net
EOF
        for i in $(seq 1 "$vdi_count"); do
            echo "      - crowler-vdi-$i"
        done
    } >> docker-compose.yml
fi

if [ "$vdi_count" != "0" ]; then
    for i in $(seq 1 "$vdi_count"); do
        HOST_PORT_START1=$((4444 + (i - 1) * 2))
        HOST_PORT_END1=$((4445 + (i - 1) * 2))
        HOST_PORT_START2=$((5900 + (i - 1)))
        HOST_PORT_START3=$((7900 + (i - 1)))
        HOST_PORT_START4=$((9222 + (i - 1)))
        NETWORK_NAME="crowler-vdi-$i"

        {
            echo
            echo "  crowler-vdi-$i:"
            emit_container_name "    " "crowler-vdi-$i"
            emit_runtime "    " "${cpu_limit_vdi:-1.0}" "${mem_limit_vdi_pct:-2g}"
            cat <<EOF
    env_file:
      - "$env_file"
    environment:
      - COMPOSE_PROJECT_NAME=crowler
      - INSTANCE_ID=$i
      - SE_SCREEN_WIDTH=1920
      - SE_SCREEN_HEIGHT=1080
      - SE_SCREEN_DEPTH=24
      - SE_ROLE=standalone
      - SE_REJECT_UNSUPPORTED_CAPS=true
      - SE_NODE_ENABLE_CDP=true
      - SE_ENABLE_TRACING=\${SE_ENABLE_TRACING:-true}
      - SE_OTEL_TRACES_EXPORTER=otlp
      - SE_OTEL_EXPORTER_ENDPOINT=\${SE_OTEL_EXPORTER_ENDPOINT:-http://crowler-jaeger:4317}
      - SEL_PASSWD=\${SEL_PASSWD:-secret}
      - TZ=\${VDI_TZ:-UTC}
      - MICROSERVICE_NAME=crowler-vdi-$i
    shm_size: "2g"
    image: zfpsystems/crowler-vdi:\${CROWLER_VDI_VERSION:-4.28.1-20260807}
EOF
            emit_pull_policy "    "
            cat <<EOF
    ports:
      - "$HOST_PORT_START1-$HOST_PORT_END1:4444-4445"
      - "$HOST_PORT_START2:5900"
      - "$HOST_PORT_START3:7900"
      - "$HOST_PORT_START4:9222"
    volumes:
      - /dev/shm:/dev/shm
    networks:
      - $NETWORK_NAME
EOF
        } >> docker-compose.yml
    done
fi

if [ "$prometheus" == "yes" ]; then
    {
        echo
        echo "  crowler-push-gateway:"
        emit_container_name "    " "crowler-push-gateway"
        emit_runtime "    " "${cpu_limit_tlm:-1.0}" "${mem_limit_tlm_pct:-2g}"
        cat <<EOF
    image: prom/pushgateway
    ports:
      - "9091:9091"
    env_file:
      - "$env_file"
    environment:
      - COMPOSE_PROJECT_NAME=crowler
      - MICROSERVICE_NAME=crowler-push-gateway
    networks:
      - crowler-net
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
EOF
    } >> docker-compose.yml
fi

cat <<EOF >> docker-compose.yml

networks:
  crowler-net:
    driver: $net_driver
EOF

for i in $(seq 1 "$vdi_count"); do
    cat <<EOF >> docker-compose.yml
  crowler-vdi-$i:
    driver: $net_driver
EOF
done

if [ "$no_api" == "0" ] || [ "$no_events" == "0" ] || [ "$postgres" == "yes" ] || [ "$engine_count" != "0" ]; then
    echo >> docker-compose.yml
    echo "volumes:" >> docker-compose.yml
fi

if [ "$no_api" == "0" ]; then
    echo "  api_data:" >> docker-compose.yml
fi

if [ "$no_events" == "0" ]; then
    echo "  events_data:" >> docker-compose.yml
fi

if [ "$postgres" == "yes" ]; then
    cat <<'EOF' >> docker-compose.yml
  db_data:
    driver: local
EOF
fi

if [ "$engine_count" != "0" ]; then
    cat <<'EOF' >> docker-compose.yml
  engine_data:
    driver: local
EOF
fi

if [ "$needs_crowler_config" == "1" ]; then
    cat <<EOF >> docker-compose.yml

configs:
  crowler_config:
    file: "$config_file"
EOF
fi

echo "docker-compose.yml has been successfully generated."
echo "Environment: $env_file"
if [ "$needs_crowler_config" == "1" ]; then
    echo "CROWler config: $config_file -> /app/config.yaml"
fi
if [ "$use_swarm" == "yes" ]; then
    echo "Mode: Docker Swarm"
else
    echo "Mode: Docker Compose"
fi
