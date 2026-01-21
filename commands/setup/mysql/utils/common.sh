#!/bin/bash
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
    local util_lines=""
    for util in "${MYSQL_UTILS[@]}"; do
        if command -v "$util" &> /dev/null; then
            util_lines+="    • $util\n"
        fi
    done
    if [ -n "$util_lines" ]; then
        log_output "  ${CYAN}Utilitários:${NC}\n$util_lines"
    fi
}
