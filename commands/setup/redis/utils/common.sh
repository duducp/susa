#!/bin/bash
# Redis CLI Common Utilities
# Shared functions used across install, update and uninstall

# Source homebrew library
source "$LIB_DIR/homebrew.sh"

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

    local util_lines=""
    for util in "${REDIS_UTILS[@]}"; do
        if command -v "$util" &> /dev/null; then
            util_lines+="    • $util\n"
        fi
    done

    if [ -n "$util_lines" ]; then
        log_output "  ${CYAN}Utilitários:${NC}\n$util_lines"
    fi
}
