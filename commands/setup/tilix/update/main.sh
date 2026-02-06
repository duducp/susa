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
    log_output "${LIGHT_GREEN}Detalhes da atualização:${NC}"
    log_output "  Atualiza o Tilix via gerenciador de pacotes do sistema."
    log_output "  O comando atualiza a lista de pacotes antes de atualizar."
}

# Main update function
main() {
    # Verify it's Linux
    if [[ "$(uname -s)" != "Linux" ]]; then
        log_error "Tilix só está disponível para Linux"
        exit 1
    fi

    log_info "Atualizando Tilix..."

    local pkg_manager=$(detect_package_manager)
    log_debug "Gerenciador de pacotes detectado: $pkg_manager"

    # Check if Tilix is installed
    if ! check_installation; then
        log_error "Tilix não está instalado"
        echo ""
        log_output "${YELLOW}Para instalar, execute:${NC}"
        echo "  susa setup tilix install"
        return 1
    fi

    local current_version=$(get_current_version)
    log_debug "Versão atual: $current_version"

    # Update package lists
    update_package_lists "$pkg_manager"

    # Update Tilix
    update_tilix_package "$pkg_manager"

    local new_version=$(get_current_version)

    if [ "$current_version" = "$new_version" ]; then
        log_info "Tilix já está na versão mais recente ($current_version)"
    else
        log_success "Tilix atualizado de $current_version para $new_version"
        register_or_update_software_in_lock "$COMMAND_NAME" "$new_version"
    fi

    log_debug "Atualização concluída"
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
