#!/bin/bash
# PostgreSQL Client Common Utilities
# Shared functions used across install, update and uninstall

# Source homebrew library
source "$LIB_DIR/homebrew.sh"

# Constants
POSTGRES_CLIENT_PKG_DEBIAN="postgresql-client"
POSTGRES_CLIENT_PKG_REDHAT="postgresql"
POSTGRES_CLIENT_PKG_ARCH="postgresql-libs"
POSTGRES_CLIENT_PKG_HOMEBREW="libpq"
POSTGRES_UTILS=("psql" "pg_dump" "pg_restore" "createdb" "dropdb" "pg_isready")
POSTGRES_HOMEBREW_PATH="/opt/homebrew/opt/libpq/bin"
POSTGRES_BIN_NAME="psql"

# Get latest version from PostgreSQL official repository
get_latest_version() {
    log_debug "Detectando método de instalação para obter a última versão do PostgreSQL Client..."
    local os_name pkg_manager version
    os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$os_name" in
        darwin)
            # Homebrew - use homebrew_get_latest_version_formula
            if homebrew_is_available; then
                version=$(homebrew_get_latest_version_formula "$POSTGRES_CLIENT_PKG_HOMEBREW")
                log_debug "Última versão via Homebrew: $version"
                if [ -n "$version" ] && [ "$version" != "unknown" ]; then
                    echo "$version"
                    return 0
                fi
            fi
            ;;
        linux)
            # Detect distro
            local distro="$(get_distro_id)"
            case "$distro" in
                ubuntu | debian | pop | linuxmint)
                    # apt - extrair versão do PostgreSQL (major apenas, ex: 16)
                    version=$(apt-cache policy postgresql-client 2> /dev/null | grep Candidate | awk '{print $2}' | grep -oE '^[0-9]+' | head -1)
                    log_debug "Última versão via apt: $version"
                    if [ -n "$version" ]; then
                        echo "$version"
                        return 0
                    fi
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    # dnf/yum
                    pkg_manager=$(get_redhat_pkg_manager)
                    version=$($pkg_manager info postgresql 2> /dev/null | grep -E '^Version' | awk '{print $2}' | grep -oE '[0-9]+\.[0-9]+' | head -1)
                    log_debug "Última versão via $pkg_manager: $version"
                    if [ -n "$version" ]; then
                        echo "$version"
                        return 0
                    fi
                    ;;
                arch | manjaro)
                    # pacman
                    version=$(pacman -Si postgresql-libs 2> /dev/null | grep Version | awk '{print $3}' | grep -oE '[0-9]+\.[0-9]+' | head -1)
                    log_debug "Última versão via pacman: $version"
                    if [ -n "$version" ]; then
                        echo "$version"
                        return 0
                    fi
                    ;;
            esac
            ;;
    esac

    log_debug "Não foi possível obter a versão mais recente. Retornando vazio."
    echo ""
    return 1
}

# Get installed PostgreSQL client version
get_current_version() {
    if check_installation; then
        # psql return: "psql (PostgreSQL) 16.6"
        # Extract only major (16) to compare with get_latest_version
        ${POSTGRES_BIN_NAME} --version 2> /dev/null | grep -oE '[0-9]+' | head -1 || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Check if PostgreSQL client is installed
check_installation() {
    command -v ${POSTGRES_BIN_NAME} &> /dev/null
}

# Show additional PostgreSQL-specific information
show_additional_info() {
    if ! check_installation; then
        return
    fi
    local util_lines=""
    for util in "${POSTGRES_UTILS[@]}"; do
        if command -v "$util" &> /dev/null; then
            util_lines+="    • $util\n"
        fi
    done
    if [ -n "$util_lines" ]; then
        log_output "  ${CYAN}Utilitários:${NC}\n$util_lines"
    fi
}
