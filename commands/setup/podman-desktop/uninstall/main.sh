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
    local skip_confirm=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y | --yes)
                skip_confirm=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    log_info "Desinstalando Podman Desktop..."

    if ! check_installation; then
        log_info "Podman Desktop não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)
    log_debug "Versão a ser removida: $current_version"

    log_output ""
    if [ "$skip_confirm" = "false" ]; then
        log_output "${YELLOW}Deseja realmente desinstalar o Podman Desktop $current_version? (s/N)${NC}"
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    if is_mac; then
        if homebrew_is_installed "$HOMEBREW_CASK"; then
            homebrew_uninstall "$HOMEBREW_CASK" "$PODMAN_DESKTOP_NAME"
        else
            log_error "Podman Desktop não está instalado via Homebrew"
            return 1
        fi
    else
        if flatpak_is_installed "$FLATPAK_APP_ID"; then
            flatpak_uninstall "$FLATPAK_APP_ID" "$PODMAN_DESKTOP_NAME"
        else
            log_error "Podman Desktop não está instalado via Flatpak"
            return 1
        fi
    fi

    if ! check_installation; then
        remove_software_in_lock "podman-desktop"
        log_success "Podman Desktop desinstalado com sucesso!"
    else
        log_error "Falha ao desinstalar Podman Desktop completamente"
        return 1
    fi
}

[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
