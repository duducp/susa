#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"

# Get utilities directory
UTILS_DIR="$(dirname "$(readlink -f "$0")")/../utils"
source "$UTILS_DIR/common.sh"

# Help function
show_complement_help() {
    log_output "${LIGHT_GREEN}Detalhes da instalação:${NC}"
    log_output "  • macOS: Instala via Homebrew Cask"
    log_output "  • Linux: Adiciona repositório oficial e instala via gerenciador de pacotes"
    log_output "    - Debian/Ubuntu: apt"
    log_output "    - Fedora/RHEL/CentOS: dnf/yum"
    log_output "    - Arch: pacman/AUR"
    log_output ""
    log_output "${LIGHT_GREEN}Após a instalação:${NC}"
    log_output "  1. Execute: ${LIGHT_CYAN}subl${NC} para abrir o editor"
    log_output "  2. Instale o Package Control: Ctrl/Cmd+Shift+P → Install Package Control"
    log_output "  3. Use ${LIGHT_CYAN}susa setup sublime-text --help${NC} para mais informações"
}

# Main installation function
main() {
    if check_installation; then
        log_info "Sublime Text $(get_current_version) já está instalado."
        exit 0
    fi

    log_info "Iniciando instalação do Sublime Text..."

    # Detect OS and install
    if is_mac; then
        install_sublime_macos
    else
        install_sublime_linux
    fi

    local install_result=$?

    if [ $install_result -eq 0 ]; then
        # Verify installation
        if check_installation; then
            local installed_version=$(get_current_version)

            # Mark as installed in lock file
            register_or_update_software_in_lock "$COMMAND_NAME" "$installed_version"

            log_success "Sublime Text $installed_version instalado com sucesso!"
            log_output ""
            log_output "Próximos passos:"
            log_output "  1. Execute: ${LIGHT_CYAN}subl${NC} para abrir o editor"
            log_output "  2. Instale o Package Control: Ctrl/Cmd+Shift+P → Install Package Control"
            log_output "  3. Use ${LIGHT_CYAN}susa setup sublime-text --help${NC} para mais informações"
            log_output ""
            log_output "${LIGHT_GREEN}Dica:${NC} Explore os temas e plugins em https://packagecontrol.io"
        else
            log_error "Sublime Text foi instalado mas não está disponível no PATH"
            return 1
        fi
    else
        return $install_result
    fi
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
