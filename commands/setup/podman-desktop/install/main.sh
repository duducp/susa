#!/usr/bin/env zsh

UTILS_DIR="$(dirname "$0")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/flatpak.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

# Install on macOS
install_macos() {
    if ! homebrew_is_installed "$HOMEBREW_CASK"; then
        homebrew_install "$HOMEBREW_CASK" "$PODMAN_DESKTOP_NAME"
    else
        log_warning "Podman Desktop já está instalado via Homebrew"
    fi
    return 0
}

# Install on Linux
install_linux() {
    flatpak_install "$FLATPAK_APP_ID" "$PODMAN_DESKTOP_NAME"
    return $?
}

# Main function
main() {
    if check_installation; then
        log_info "Podman Desktop $(get_current_version) já está instalado."
        log_output ""
        log_output "Use ${LIGHT_CYAN}susa setup podman-desktop update${NC} para atualizar"
        return 0
    fi

    log_info "Iniciando instalação do Podman Desktop..."

    if is_mac; then
        install_macos
    else
        install_linux
    fi

    local install_result=$?

    if [ $install_result -eq 0 ]; then
        if check_installation; then
            local installed_version=$(get_current_version)
            register_or_update_software_in_lock "podman-desktop" "$installed_version"
            log_success "Podman Desktop $installed_version instalado com sucesso!"
        else
            log_error "Podman Desktop foi instalado mas não está disponível"
            return 1
        fi
    else
        return $install_result
    fi
}

[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
