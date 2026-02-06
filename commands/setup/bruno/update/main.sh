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
    log_info "Atualizando Bruno..."

    if ! check_installation; then
        log_error "Bruno não está instalado."
        log_output "Use ${LIGHT_CYAN}susa setup bruno install${NC} para instalar"
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"

    if is_mac; then
        if homebrew_is_installed "$BRUNO_HOMEBREW_CASK"; then
            homebrew_update "$BRUNO_HOMEBREW_CASK" "$BRUNO_NAME"
        else
            log_error "Bruno não está instalado via Homebrew"
            return 1
        fi
    else
        if flatpak_is_installed "$FLATPAK_APP_ID"; then
            flatpak_update "$FLATPAK_APP_ID" "$BRUNO_NAME"
        else
            log_error "Bruno não está instalado via Flatpak"
            return 1
        fi
    fi

    local new_version=$(get_current_version)
    register_or_update_software_in_lock "bruno" "$new_version"

    if [ "$current_version" = "$new_version" ]; then
        log_info "Bruno já estava na versão mais recente ($current_version)"
    else
        log_success "Bruno atualizado com sucesso para versão $new_version!"
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
