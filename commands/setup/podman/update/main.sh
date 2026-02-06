#!/usr/bin/env zsh

UTILS_DIR="$(dirname "$0")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/homebrew.sh"
source "$LIB_DIR/os.sh"
source "$UTILS_DIR/common.sh"

# Main function
main() {
    log_info "Atualizando Podman..."

    # Check if Podman is installed
    if ! check_installation; then
        log_error "Podman não está instalado. Use ${LIGHT_CYAN}susa setup podman install${NC} para instalar."
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"

    # Get latest version
    local podman_version=$(get_latest_version)
    if [ $? -ne 0 ] || [ -z "$podman_version" ]; then
        return 1
    fi
    local target_version_clean="${podman_version#v}"

    if [ "$current_version" = "$target_version_clean" ]; then
        log_info "Você já possui a versão mais recente instalada ($current_version)"
        return 0
    fi

    log_info "Atualizando de $current_version para $target_version_clean..."

    # Detect OS and update
    if is_mac; then
        update_podman_macos
    else
        update_podman_linux
    fi

    local update_result=$?

    # Verify update
    if [ $update_result -eq 0 ] && check_installation; then
        local new_version=$(get_current_version)
        log_success "Podman atualizado com sucesso para versão $new_version!"
        register_or_update_software_in_lock "$COMMAND_NAME" "$new_version"
    else
        log_error "Falha na atualização do Podman"
        return 1
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
