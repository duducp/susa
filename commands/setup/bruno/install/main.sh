#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/flatpak.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

# Install on macOS
install_macos() {
    if ! homebrew_is_installed "$BRUNO_HOMEBREW_CASK"; then
        homebrew_install "$BRUNO_HOMEBREW_CASK" "$BRUNO_NAME"
    else
        log_warning "Bruno já está instalado via Homebrew"
    fi
    return 0
}

# Install on Linux
install_linux() {
    flatpak_install "$FLATPAK_APP_ID" "$BRUNO_NAME"
    return $?
}

# Main function
main() {
    if check_installation; then
        log_info "Bruno $(get_current_version) já está instalado."
        log_output ""
        log_output "Use ${LIGHT_CYAN}susa setup bruno update${NC} para atualizar"
        return 0
    fi

    log_info "Iniciando instalação do Bruno..."

    if is_mac; then
        install_macos
    else
        install_linux
    fi

    local install_result=$?

    if [ $install_result -eq 0 ]; then
        if check_installation; then
            local installed_version=$(get_current_version)
            register_or_update_software_in_lock "bruno" "$installed_version"

            log_success "Bruno $installed_version instalado com sucesso!"
            log_output ""
            log_output "Próximos passos:"
            if is_mac; then
                log_output "  Execute: ${LIGHT_CYAN}open -a Bruno${NC}"
            else
                log_output "  Execute: ${LIGHT_CYAN}flatpak run $FLATPAK_APP_ID${NC}"
            fi
            log_output "  Ou abra pelo menu de aplicações"
        else
            log_error "Bruno foi instalado mas não está acessível"
            return 1
        fi
    else
        return $install_result
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
