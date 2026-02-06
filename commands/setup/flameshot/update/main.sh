#!/usr/bin/env zsh

UTILS_DIR="$(dirname "$0")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/flatpak.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

# Main function
main() {
    log_info "Atualizando Flameshot..."

    if ! check_installation; then
        log_error "Flameshot não está instalado"
        log_info "Use 'susa setup flameshot install' para instalar"
        return 1
    fi

    local current_version=$(get_current_version)
    log_debug "Versão atual: $current_version"

    if is_mac; then
        homebrew_update "$FLAMESHOT_HOMEBREW_CASK" "$FLAMESHOT_NAME"
    else
        flatpak_update "$FLATPAK_APP_ID" "$FLAMESHOT_NAME"
    fi

    local new_version=$(get_current_version)
    register_or_update_software_in_lock "flameshot" "$new_version"

    if [ "$new_version" != "$current_version" ]; then
        log_success "Flameshot atualizado: $current_version → $new_version"
    else
        log_info "Flameshot já está na versão mais recente ($current_version)"
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
