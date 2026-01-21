#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/flatpak.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"
source "$UTILS_DIR/update.sh"

# Help function
show_complement_help() {
    log_output "${LIGHT_GREEN}O que faz:${NC}"
    log_output "  Atualiza o DBeaver para a versão mais recente disponível."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup dbeaver update           # Atualiza o DBeaver"
    log_output "  susa setup dbeaver update -v        # Atualiza com saída detalhada"
}

# Update DBeaver
update_dbeaver() {
    log_info "Atualizando DBeaver..."

    if ! check_installation; then
        log_error "DBeaver não está instalado. Use 'susa setup dbeaver install' para instalar."
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"

    # Detect OS and update
    case "$OS_TYPE" in
        macos)
            update_dbeaver_macos
            ;;
        *)
            update_dbeaver_linux
            ;;
    esac

    # Verify update
    if check_installation; then
        local new_version=$(get_current_version)

        if [ "$new_version" != "$current_version" ]; then
            register_or_update_software_in_lock "$COMMAND_NAME" "$new_version"
            log_success "DBeaver atualizado de $current_version para $new_version"
        else
            log_info "DBeaver já está na versão mais recente ($current_version)"
        fi
    else
        log_error "DBeaver não encontrado após atualização"
        return 1
    fi
}

# Main execution
main() {
    update_dbeaver
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
