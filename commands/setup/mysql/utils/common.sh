#!/usr/bin/env zsh
# MySQL Client Common Utilities
# Shared functions used across install, update and uninstall

# Source homebrew library
source "$LIB_DIR/homebrew.sh"

# Constants
MYSQL_CLIENT_PKG_DEBIAN="mysql-client"
MYSQL_CLIENT_PKG_REDHAT="mysql"
MYSQL_CLIENT_PKG_ARCH="mysql-clients"
MYSQL_CLIENT_PKG_HOMEBREW="mysql-client"
MYSQL_UTILS=("mysql" "mysqldump" "mysqladmin" "mysqlimport")
MYSQL_HOMEBREW_PATH="/opt/homebrew/opt/mysql-client/bin"
MYSQL_BIN_NAME="mysql"

# Get latest version from MySQL official repository
get_latest_version() {
    log_debug "Detectando método de instalação para obter a última versão do MySQL Client..."
    local os_name pkg_manager version
    os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$os_name" in
        darwin)
            # Homebrew
            if homebrew_is_available; then
                version=$(homebrew_get_latest_version_formula "mysql-client")
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
                    # apt
                    version=$(apt-cache policy mysql-client | grep Candidate | awk '{print $2}' | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')
                    log_debug "Última versão via apt: $version"
                    if [ -n "$version" ]; then
                        echo "$version"
                        return 0
                    fi
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    # dnf/yum
                    pkg_manager=$(get_redhat_pkg_manager)
                    version=$($pkg_manager info mysql 2> /dev/null | grep -E '^Version' | awk '{print $2}' | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')
                    log_debug "Última versão via $pkg_manager: $version"
                    if [ -n "$version" ]; then
                        echo "$version"
                        return 0
                    fi
                    ;;
                arch | manjaro)
                    # pacman
                    version=$(pacman -Si mysql-clients 2> /dev/null | grep Version | awk '{print $3}' | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')
                    log_debug "Última versão via pacman: $version"
                    if [ -n "$version" ]; then
                        echo "$version"
                        return 0
                    fi
                    ;;
            esac
            ;;
    esac

    # Fallback: buscar do site oficial
    log_debug "Não foi possível detectar via gerenciador. Buscando do site oficial."
    local version_json
    version_json=$(curl -s https://dev.mysql.com/doc/relnotes/mysql/ | grep -oP 'MySQL Community Server \K[0-9]+(\.[0-9]+)+' | head -1 | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')
    log_debug "Versão mais recente detectada (site): $version_json"
    if [ -n "$version_json" ]; then
        echo "$version_json"
        return 0
    fi

    log_debug "Não foi possível obter a versão mais recente. Retornando vazio."
    echo ""
    return 1
}

# Get installed MySQL client version
get_current_version() {
    if check_installation; then
        ${MYSQL_UTILS[0]} --version 2> /dev/null | grep -oP '\d+(\.\d+){1,2}' | head -1 || echo ""
    fi
}

# Check if MySQL client is installed
check_installation() {
    command -v ${MYSQL_UTILS[0]} &> /dev/null
}

# Show additional MySQL-specific information
show_additional_info() {
    if ! check_installation; then
        return
    fi

    # Check if MySQL server is running
    local server_status="indisponível (client-only)"
    local server_type=""

    # Check native installation
    if command -v mysqladmin &> /dev/null && mysqladmin ping -u root 2> /dev/null | grep -q "alive"; then
        server_status="${GREEN}disponível${NC}"
        server_type=" (nativo)"
    else
        # Check Docker containers
        if command -v docker &> /dev/null; then
            local mysql_containers=$(docker ps --filter "ancestor=mysql" --filter "ancestor=mariadb" --format "{{.Names}}" 2> /dev/null)
            if [ -n "$mysql_containers" ]; then
                server_status="${GREEN}disponível${NC}"
                server_type=" (Docker)"
            fi
        fi

        # Check Podman containers
        if [ "$server_status" = "indisponível (client-only)" ] && command -v podman &> /dev/null; then
            local mysql_containers=$(podman ps --filter "ancestor=mysql" --filter "ancestor=mariadb" --format "{{.Names}}" 2> /dev/null)
            if [ -n "$mysql_containers" ]; then
                server_status="${GREEN}disponível${NC}"
                server_type=" (Podman)"
            fi
        fi
    fi

    log_output "  ${CYAN}Server:${NC} $server_status$server_type"

    # Detect MySQL port
    local port="N/A"
    if [[ "$server_status" != "indisponível"* ]]; then
        if [[ "$server_type" == " (nativo)" ]] && command -v mysqladmin &> /dev/null; then
            # Native installation
            port=$(mysqladmin variables -u root 2> /dev/null | grep -E "^\| port" | awk '{print $4}')
        elif [[ "$server_type" == " (Docker)" ]]; then
            # Docker container
            port=$(docker ps --filter "ancestor=mysql" --filter "ancestor=mariadb" --format "{{.Ports}}" 2> /dev/null | head -n1 | grep -oP '\d+(?=->3306)')
            [ -z "$port" ] && port="3306" # Default MySQL port
        elif [[ "$server_type" == " (Podman)" ]]; then
            # Podman container
            port=$(podman ps --filter "ancestor=mysql" --filter "ancestor=mariadb" --format "{{.Ports}}" 2> /dev/null | head -n1 | grep -oP '\d+(?=->3306)')
            [ -z "$port" ] && port="3306" # Default MySQL port
        fi
    fi
    [ -n "$port" ] && [ "$port" != "N/A" ] && log_output "  ${CYAN}Porta:${NC} $port"

    # List available utilities
    local utils_found=()
    for util in "${MYSQL_UTILS[@]}"; do
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
