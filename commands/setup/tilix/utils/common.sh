#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source required libraries
source "$LIB_DIR/github.sh"

# Constants
TILIX_NAME="Tilix"
TILIX_REPO="gnunn1/tilix"
TILIX_BIN_NAME="tilix"
TILIX_PKG_DEB="tilix"
TILIX_PKG_RPM="tilix"
TILIX_PKG_ARCH="tilix"
TILIX_PKG_ZYPPER="tilix"

# ============================================================================
# MANDATORY FUNCTIONS (Required by SUSA standards)
# ============================================================================

# Check if Tilix is installed
check_installation() {
    command -v $TILIX_BIN_NAME &> /dev/null || ([ "$(uname)" = "Linux" ] && dpkg -l 2> /dev/null | grep -q $TILIX_PKG_DEB)
}

# Get installed Tilix version
get_current_version() {
    if check_installation; then
        # Try to get version from package manager instead of executing binary
        if command -v dpkg &> /dev/null && dpkg -l $TILIX_PKG_DEB 2> /dev/null | grep -q '^ii'; then
            dpkg -l $TILIX_PKG_DEB 2> /dev/null | grep '^ii' | awk '{print $3}' | cut -d'-' -f1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida"
        elif command -v rpm &> /dev/null && rpm -q $TILIX_PKG_RPM &> /dev/null; then
            rpm -q --queryformat '%{VERSION}' $TILIX_PKG_RPM 2> /dev/null || echo "desconhecida"
        elif command -v pacman &> /dev/null && pacman -Q $TILIX_PKG_ARCH &> /dev/null; then
            pacman -Q $TILIX_PKG_ARCH 2> /dev/null | awk '{print $2}' | cut -d'-' -f1 || echo "desconhecida"
        elif command -v zypper &> /dev/null && zypper se --installed-only $TILIX_PKG_ZYPPER &> /dev/null; then
            zypper info $TILIX_PKG_ZYPPER 2> /dev/null | grep -E '^Version' | awk '{print $2}' || echo "desconhecida"
        else
            # Fallback: try executing binary (may fail)
            $TILIX_BIN_NAME --version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida"
        fi
    else
        echo "desconhecida"
    fi
}

# Get latest Tilix version from GitHub
get_latest_version() {
    github_get_latest_version "$TILIX_REPO"
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Detect package manager
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt"
        log_debug "Gerenciador de pacotes: apt (Debian/Ubuntu)"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
        log_debug "Gerenciador de pacotes: dnf (Fedora)"
    elif command -v yum &> /dev/null; then
        echo "yum"
        log_debug "Gerenciador de pacotes: yum (RHEL/CentOS)"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
        log_debug "Gerenciador de pacotes: pacman (Arch Linux)"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
        log_debug "Gerenciador de pacotes: zypper (openSUSE)"
    else
        echo "unknown"
        log_debug "Nenhum gerenciador de pacotes conhecido detectado"
    fi
}

# Update package lists
update_package_lists() {
    local pkg_manager="$1"

    log_info "Atualizando lista de pacotes..."
    case "$pkg_manager" in
        apt)
            log_debug "Executando: sudo apt-get update"
            sudo apt-get update 2>&1 | while read -r line; do log_debug "apt: $line"; done || true
            ;;
        dnf)
            log_debug "Executando: sudo dnf check-update"
            sudo dnf check-update 2>&1 | while read -r line; do log_debug "dnf: $line"; done || true
            ;;
        yum)
            log_debug "Executando: sudo yum check-update"
            sudo yum check-update 2>&1 | while read -r line; do log_debug "yum: $line"; done || true
            ;;
        pacman)
            log_debug "Executando: sudo pacman -Sy"
            sudo pacman -Sy 2>&1 | while read -r line; do log_debug "pacman: $line"; done || true
            ;;
        zypper)
            log_debug "Executando: sudo zypper refresh"
            sudo zypper refresh 2>&1 | while read -r line; do log_debug "zypper: $line"; done || true
            ;;
    esac
}

# Install Tilix package
install_tilix_package() {
    local pkg_manager="$1"

    log_info "Instalando Tilix via $pkg_manager..."
    case "$pkg_manager" in
        apt)
            log_debug "Executando: sudo apt-get install -y $TILIX_PKG_DEB"
            sudo apt-get install -y $TILIX_PKG_DEB 2>&1 | while read -r line; do log_debug "apt: $line"; done
            ;;
        dnf)
            log_debug "Executando: sudo dnf install -y $TILIX_PKG_RPM"
            sudo dnf install -y $TILIX_PKG_RPM 2>&1 | while read -r line; do log_debug "dnf: $line"; done
            ;;
        yum)
            log_debug "Executando: sudo yum install -y $TILIX_PKG_RPM"
            sudo yum install -y $TILIX_PKG_RPM 2>&1 | while read -r line; do log_debug "yum: $line"; done
            ;;
        pacman)
            log_debug "Executando: sudo pacman -S --noconfirm $TILIX_PKG_ARCH"
            sudo pacman -S --noconfirm $TILIX_PKG_ARCH 2>&1 | while read -r line; do log_debug "pacman: $line"; done
            ;;
        zypper)
            log_debug "Executando: sudo zypper install -y $TILIX_PKG_ZYPPER"
            sudo zypper install -y $TILIX_PKG_ZYPPER 2>&1 | while read -r line; do log_debug "zypper: $line"; done
            ;;
    esac
}

# Update Tilix package
update_tilix_package() {
    local pkg_manager="$1"

    log_info "Atualizando Tilix via $pkg_manager..."
    case "$pkg_manager" in
        apt)
            log_debug "Executando: sudo apt-get upgrade -y $TILIX_PKG_DEB"
            sudo apt-get upgrade -y $TILIX_PKG_DEB 2>&1 | while read -r line; do log_debug "apt: $line"; done
            ;;
        dnf)
            log_debug "Executando: sudo dnf upgrade -y $TILIX_PKG_RPM"
            sudo dnf upgrade -y $TILIX_PKG_RPM 2>&1 | while read -r line; do log_debug "dnf: $line"; done
            ;;
        yum)
            log_debug "Executando: sudo yum update -y $TILIX_PKG_RPM"
            sudo yum update -y $TILIX_PKG_RPM 2>&1 | while read -r line; do log_debug "yum: $line"; done
            ;;
        pacman)
            log_debug "Executando: sudo pacman -S $TILIX_PKG_ARCH"
            sudo pacman -S $TILIX_PKG_ARCH 2>&1 | while read -r line; do log_debug "pacman: $line"; done
            ;;
        zypper)
            log_debug "Executando: sudo zypper update -y $TILIX_PKG_ZYPPER"
            sudo zypper update -y $TILIX_PKG_ZYPPER 2>&1 | while read -r line; do log_debug "zypper: $line"; done
            ;;
    esac
}

# Uninstall Tilix package
uninstall_tilix_package() {
    local pkg_manager="$1"
    local skip_confirm="${2:-false}"

    log_info "Removendo Tilix via $pkg_manager..."
    case "$pkg_manager" in
        apt)
            log_debug "Executando: sudo apt-get remove -y $TILIX_PKG_DEB"
            sudo apt-get remove -y $TILIX_PKG_DEB 2>&1 | while read -r line; do log_debug "apt: $line"; done

            # Ask about purge
            if [ "$skip_confirm" = false ]; then
                echo ""
                log_output "${YELLOW}Deseja remover também os arquivos de configuração do sistema? (s/N)${NC}"
                read -r purge_response

                if [[ "$purge_response" =~ ^[sSyY]$ ]]; then
                    log_debug "Executando: sudo apt-get purge -y $TILIX_PKG_DEB"
                    sudo apt-get purge -y $TILIX_PKG_DEB 2>&1 | while read -r line; do log_debug "apt: $line"; done
                    log_debug "Executando: sudo apt-get autoremove -y"
                    sudo apt-get autoremove -y 2>&1 | while read -r line; do log_debug "apt: $line"; done
                fi
            else
                # Auto-purge when --yes is used
                log_debug "Executando: sudo apt-get purge -y $TILIX_PKG_DEB"
                sudo apt-get purge -y $TILIX_PKG_DEB 2>&1 | while read -r line; do log_debug "apt: $line"; done
                log_debug "Executando: sudo apt-get autoremove -y"
                sudo apt-get autoremove -y 2>&1 | while read -r line; do log_debug "apt: $line"; done
            fi
            ;;
        dnf)
            log_debug "Executando: sudo dnf remove -y $TILIX_PKG_RPM"
            sudo dnf remove -y $TILIX_PKG_RPM 2>&1 | while read -r line; do log_debug "dnf: $line"; done
            ;;
        yum)
            log_debug "Executando: sudo yum remove -y $TILIX_PKG_RPM"
            sudo yum remove -y $TILIX_PKG_RPM 2>&1 | while read -r line; do log_debug "yum: $line"; done
            ;;
        pacman)
            log_debug "Executando: sudo pacman -R $TILIX_PKG_ARCH"
            sudo pacman -R $TILIX_PKG_ARCH 2>&1 | while read -r line; do log_debug "pacman: $line"; done
            ;;
        zypper)
            log_debug "Executando: sudo zypper remove -y $TILIX_PKG_ZYPPER"
            sudo zypper remove -y $TILIX_PKG_ZYPPER 2>&1 | while read -r line; do log_debug "zypper: $line"; done
            ;;
    esac
}

# Remove user configurations
remove_user_configurations() {
    echo ""
    log_output "${YELLOW}Deseja remover as configurações de usuário do Tilix? (s/N)${NC}"
    read -r config_response

    if [[ "$config_response" =~ ^[sSyY]$ ]]; then
        rm -rf "$HOME/.config/tilix" 2> /dev/null || true
        rm -rf "$HOME/.local/share/tilix" 2> /dev/null || true
        dconf reset -f /com/gexperts/Tilix/ 2> /dev/null || true
        log_success "Configurações removidas"
    else
        log_info "Configurações mantidas em ~/.config/tilix"
    fi
}
