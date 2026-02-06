#!/usr/bin/env zsh
# Redis CLI Common Utilities
# Shared functions used across install, update and uninstall

# Source libraries
source "$LIB_DIR/homebrew.sh"
source "$LIB_DIR/github.sh"

# Constants
REDIS_CLI_BIN_NAME="redis-cli"
REDIS_PKG_MACOS="redis"
REDIS_PKG_DEBIAN="redis-tools"
REDIS_PKG_REDHAT="redis"
REDIS_PKG_ARCH="redis"
REDIS_UTILS=("redis-cli" "redis-benchmark")

# Get latest version from Redis GitHub
get_latest_version() {
    local version
    version=$(github_get_latest_version "redis/redis")
    log_debug "Última versão do Redis: $version"
    echo "$version"
}

# Get installed Redis CLI version
get_current_version() {
    if check_installation; then
        $REDIS_CLI_BIN_NAME --version 2> /dev/null | grep -oE '[0-9]+' | head -1 || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Check if Redis CLI is installed
check_installation() {
    command -v $REDIS_CLI_BIN_NAME &> /dev/null
}

# Show additional Redis-specific information
show_additional_info() {
    if ! check_installation; then
        return
    fi

    # Check if Redis server is running
    local server_status="indisponível (client-only)"
    local server_type=""

    # Check native installation first (process running)
    if pgrep -x redis-server > /dev/null 2>&1 || systemctl is-active --quiet redis 2> /dev/null; then
        server_status="${GREEN}disponível${NC}"
        server_type=" (nativo)"
    else
        # Check Docker containers
        if command -v docker &> /dev/null; then
            local redis_containers=$(docker ps --filter "ancestor=redis" --format "{{.Names}}" 2> /dev/null)
            if [ -n "$redis_containers" ]; then
                server_status="${GREEN}disponível${NC}"
                server_type=" (Docker)"
            fi
        fi

        # Check Podman containers
        if [ "$server_status" = "indisponível (client-only)" ] && command -v podman &> /dev/null; then
            local redis_containers=$(podman ps --filter "ancestor=redis" --format "{{.Names}}" 2> /dev/null)
            if [ -n "$redis_containers" ]; then
                server_status="${GREEN}disponível${NC}"
                server_type=" (Podman)"
            fi
        fi
    fi

    log_output "  ${CYAN}Server:${NC} $server_status$server_type"

    # Detect Redis port (native, Docker or Podman)
    local port="N/A"
    if [[ "$server_status" != "indisponível"* ]]; then
        if [[ "$server_type" == " (nativo)" ]]; then
            # Native installation - check process port binding
            if command -v redis-cli &> /dev/null && redis-cli ping > /dev/null 2>&1; then
                port=$(redis-cli CONFIG GET port 2> /dev/null | tail -n 1)
            fi
            # Fallback: check ps output for port
            if [ -z "$port" ] || [ "$port" = "N/A" ]; then
                port=$(ps aux | grep "redis-server.*:.*" | grep -v grep | grep -oP ':\K[0-9]+' | head -n1)
            fi
        elif [[ "$server_type" == " (Docker)" ]]; then
            # Docker container - extract mapped host port
            local docker_ports=$(docker ps --filter "ancestor=redis" --format "{{.Ports}}" 2> /dev/null | head -n1)
            port=$(echo "$docker_ports" | grep -oP '\d+(?=->6379)' | head -n1)
            [ -z "$port" ] && port="6379" # Default if only internal port
        elif [[ "$server_type" == " (Podman)" ]]; then
            # Podman container - extract mapped host port
            local podman_ports=$(podman ps --filter "ancestor=redis" --format "{{.Ports}}" 2> /dev/null | head -n1)
            port=$(echo "$podman_ports" | grep -oP '\d+(?=->6379)' | head -n1)
            [ -z "$port" ] && port="6379" # Default if only internal port
        fi
    fi
    [ -n "$port" ] && [ "$port" != "N/A" ] && log_output "  ${CYAN}Porta:${NC} $port"

    # List available utilities
    local utils_found=()
    for util in "${REDIS_UTILS[@]}"; do
        if command -v "$util" &> /dev/null; then
            utils_found+=("$util")
        fi
    done

    if [ ${#utils_found[@]} -gt 0 ]; then
        local utils_list=$(printf "%s, " "${utils_found[@]}")
        utils_list="${utils_list%, }" # Remove trailing comma
        log_output "  ${CYAN}Utilitários:${NC} $utils_list"
    fi
}
