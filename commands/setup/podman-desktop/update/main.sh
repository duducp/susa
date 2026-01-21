#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/flatpak.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

# Main function
main() {
    log_info "Atualizando Podman Desktop..."

    if ! check_installation; then
        log_error "Podman Desktop não está instalado."
        log_output "Use ${LIGHT_CYAN}susa setup podman-desktop install${NC} para instalar"
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"

    if is_mac; then
        if homebrew_is_installed "$HOMEBREW_CASK"; then
            homebrew_update "$HOMEBREW_CASK" "$PODMAN_DESKTOP_NAME"
        else
            log_error "Podman Desktop não está instalado via Homebrew"
            return 1
        fi
    else
        if flatpak_is_installed "$FLATPAK_APP_ID"; then
            flatpak_update "$FLATPAK_APP_ID" "$PODMAN_DESKTOP_NAME"
        else
            log_error "Podman Desktop não está instalado via Flatpak"
            return 1
        fi
    fi

    local new_version=$(get_current_version)
    register_or_update_software_in_lock "podman-desktop" "$new_version"

    if [ "$current_version" = "$new_version" ]; then
        log_info "Podman Desktop já estava na versão mais recente ($current_version)"
    else
        log_success "Podman Desktop atualizado com sucesso para versão $new_version!"
    fi
}

[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
