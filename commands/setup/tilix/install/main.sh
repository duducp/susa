#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"

# Get utilities directory
UTILS_DIR="$(dirname "$(readlink -f "$0")")/../utils"
source "$UTILS_DIR/common.sh"

# Help function
show_complement_help() {
    log_output "${LIGHT_GREEN}Detalhes da instalação:${NC}"
    log_output "  • Debian/Ubuntu: apt-get"
    log_output "  • Fedora: dnf"
    log_output "  • RHEL/CentOS: yum"
    log_output "  • Arch Linux: pacman"
    log_output "  • openSUSE: zypper"
    log_output ""
    log_output "${LIGHT_GREEN}Após a instalação:${NC}"
    log_output "  Para melhor integração, adicione ao seu ~/.bashrc ou ~/.zshrc:"
    log_output "    ${LIGHT_CYAN}source /etc/profile.d/vte.sh${NC}"
}

# Main installation function
main() {
    # Verify it's Linux
    if [[ "$(uname -s)" != "Linux" ]]; then
        log_error "Tilix só está disponível para Linux"
        exit 1
    fi
    log_debug "Sistema operacional: Linux $(uname -r)"

    if check_installation; then
        log_info "Tilix $(get_current_version) já está instalado."
        exit 0
    fi

    log_info "Iniciando instalação do Tilix..."

    local pkg_manager=$(detect_package_manager)
    log_debug "Gerenciador de pacotes detectado: $pkg_manager"

    if [ "$pkg_manager" = "unknown" ]; then
        log_error "Gerenciador de pacotes não suportado"
        echo ""
        log_output "${YELLOW}Instalação manual necessária:${NC}"
        log_output "  Visite: https://gnunn1.github.io/tilix-web/"
        return 1
    fi

    # Update package lists
    update_package_lists "$pkg_manager"

    # Install Tilix
    install_tilix_package "$pkg_manager"

    # Verify installation
    if check_installation; then
        local version=$(get_current_version)
        log_success "Tilix $version instalado com sucesso!"
        register_or_update_software_in_lock "$COMMAND_NAME" "$version"

        # Check for VTE configuration
        if [ -f /etc/profile.d/vte.sh ]; then
            log_debug "VTE config encontrado: /etc/profile.d/vte.sh"
            echo ""
            log_info "Para melhor integração, adicione ao seu ~/.bashrc ou ~/.zshrc:"
            echo "  source /etc/profile.d/vte.sh"
        fi

        return 0
    else
        log_error "Falha ao verificar instalação do Tilix"
        return 1
    fi
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
