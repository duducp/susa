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

    local version=$(brew info --json=v2 "$formula_name" 2> /dev/null | grep -oE '"stable":"[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "unknown")

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
