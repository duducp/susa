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
            if command -v brew &> /dev/null; then
                version=$(brew info --json=v2 mysql-client | grep -oP '"versions":\s*\{[^}]*"stable":\s*"\K[0-9]+(\.[0-9]+)+' | head -1)
                log_debug "Última versão via Homebrew: $version"
                if [ -n "$version" ]; then
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
        ${MYSQL_UTILS[0]} --version 2> /dev/null | grep -oP '\d+(\.\d+){1,2}' | head -1 || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Check if MySQL client is installed
check_installation() {
    command -v ${MYSQL_UTILS[0]} &> /dev/null
}

# Helper: Get latest version for Homebrew formula (not cask)
homebrew_get_latest_version_formula() {
    local formula_name="${1:-}"

    if [ -z "$formula_name" ]; then
        echo "unknown"
        return 1
    fi

    if ! homebrew_is_available; then
        echo "unknown"
        return 1
    fi

    local version=$(brew info --json=v2 "$formula_name" 2> /dev/null | grep -oP '"versions":\s*\{[^}]*"stable":\s*"\K[0-9]+(\.[0-9]+)+' | head -1 || echo "unknown")

    if [ "$version" = "unknown" ] || [ -z "$version" ]; then
        echo "unknown"
        return 1
    fi

    echo "$version"
    return 0
}

# Helper: Check if Homebrew formula is installed
homebrew_is_installed_formula() {
    local formula_name="${1:-}"

    if [ -z "$formula_name" ]; then
        return 1
    fi

    if ! homebrew_is_available; then
        return 1
    fi

    brew list "$formula_name" &> /dev/null
}

# Helper: Get installed version of Homebrew formula
homebrew_get_installed_version_formula() {
    local formula_name="${1:-}"

    if [ -z "$formula_name" ]; then
        echo "unknown"
        return 0
    fi

    if ! homebrew_is_installed_formula "$formula_name"; then
        echo "unknown"
        return 0
    fi

    local version=$(brew list --versions "$formula_name" 2> /dev/null | awk '{print $2}' | head -1 || echo "unknown")
    echo "$version"
}

# Helper: Install Homebrew formula
homebrew_install_formula() {
    local formula_name="${1:-}"
    local app_name="${2:-$formula_name}"

    if [ -z "$formula_name" ]; then
        log_error "Nome da formula é obrigatório"
        return 1
    fi

    if ! homebrew_is_available; then
        log_error "Homebrew não está instalado"
        return 1
    fi

    # Check if already installed
    if homebrew_is_installed_formula "$formula_name"; then
        local version=$(homebrew_get_installed_version_formula "$formula_name")
        log_info "$app_name $version já está instalado"
        return 0
    fi

    log_debug "Instalando formula: $formula_name"
    if ! brew install "$formula_name" 2>&1 | while read -r line; do log_debug "brew: $line"; done; then
        log_error "Falha ao instalar $app_name via Homebrew"
        return 1
    fi

    return 0
}

# Helper: Update Homebrew formula
homebrew_update_formula() {
    local formula_name="${1:-}"
    local app_name="${2:-$formula_name}"

    if [ -z "$formula_name" ]; then
        log_error "Nome da formula é obrigatório"
        return 1
    fi

    if ! homebrew_is_available; then
        log_error "Homebrew não está instalado"
        return 1
    fi

    if ! homebrew_is_installed_formula "$formula_name"; then
        log_error "$app_name não está instalado"
        return 1
    fi

    log_debug "Atualizando formula: $formula_name"
    if brew upgrade "$formula_name" 2>&1 | while read -r line; do log_debug "brew: $line"; done; then
        return 0
    else
        # Pode já estar atualizado
        return 0
    fi
}

# Helper: Uninstall Homebrew formula
homebrew_uninstall_formula() {
    local formula_name="${1:-}"
    local app_name="${2:-$formula_name}"

    if [ -z "$formula_name" ]; then
        log_error "Nome da formula é obrigatório"
        return 1
    fi

    if ! homebrew_is_available; then
        log_error "Homebrew não está instalado"
        return 1
    fi

    if ! homebrew_is_installed_formula "$formula_name"; then
        log_debug "$app_name não está instalado"
        return 0
    fi

    log_debug "Desinstalando formula: $formula_name"
    if ! brew uninstall "$formula_name" 2>&1 | while read -r line; do log_debug "brew: $line"; done; then
        log_error "Falha ao desinstalar $app_name via Homebrew"
        return 1
    fi

    return 0
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
