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

    # Check if PostgreSQL server is running
    local server_status="indisponível (client-only)"
    local server_type=""

    # Check native installation
    if command -v pg_isready &> /dev/null && pg_isready -q 2> /dev/null; then
        server_status="${GREEN}disponível${NC}"
        server_type=" (nativo)"
    else
        # Check Docker containers
        if command -v docker &> /dev/null; then
            local postgres_containers=$(docker ps --filter "ancestor=postgres" --format "{{.Names}}" 2> /dev/null)
            if [ -n "$postgres_containers" ]; then
                server_status="${GREEN}disponível${NC}"
                server_type=" (Docker)"
            fi
        fi

        # Check Podman containers
        if [ "$server_status" = "indisponível (client-only)" ] && command -v podman &> /dev/null; then
            local postgres_containers=$(podman ps --filter "ancestor=postgres" --format "{{.Names}}" 2> /dev/null)
            if [ -n "$postgres_containers" ]; then
                server_status="${GREEN}disponível${NC}"
                server_type=" (Podman)"
            fi
        fi
    fi

    log_output "  ${CYAN}Server:${NC} $server_status$server_type"

    # Detect PostgreSQL port (native, Docker or Podman)
    local port="N/A"
    if [[ "$server_status" != "indisponível"* ]]; then
        if [[ "$server_type" == " (nativo)" ]] && command -v psql &> /dev/null; then
            # Native installation
            port=$(psql -U postgres -t -c "SHOW port;" 2> /dev/null | xargs)
            [ -z "$port" ] && port="5432" # Default PostgreSQL port
        elif [[ "$server_type" == " (Docker)" ]]; then
            # Docker container
            port=$(docker ps --filter "ancestor=postgres" --format "{{.Ports}}" 2> /dev/null | head -n1 | grep -oP '\d+(?=->5432)')
            [ -z "$port" ] && port="5432" # Default PostgreSQL port
        elif [[ "$server_type" == " (Podman)" ]]; then
            # Podman container
            port=$(podman ps --filter "ancestor=postgres" --format "{{.Ports}}" 2> /dev/null | head -n1 | grep -oP '\d+(?=->5432)')
            [ -z "$port" ] && port="5432" # Default PostgreSQL port
        fi
    fi
    [ -n "$port" ] && [ "$port" != "N/A" ] && log_output "  ${CYAN}Porta:${NC} $port"

    # List available utilities
    local utils_found=()
    for util in "${POSTGRES_UTILS[@]}"; do
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
