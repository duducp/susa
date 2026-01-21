#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/snap.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"
source "$UTILS_DIR/update.sh"

# Show additional info in command help
show_complement_help() {
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Atualiza o NordPass para a versão mais recente disponível."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup nordpass update              # Atualiza o NordPass"
    log_output "  susa setup nordpass update -v           # Atualiza com saída detalhada"
    log_output ""
    log_output "${LIGHT_GREEN}Comportamento:${NC}"
    log_output "  • macOS: Usa Homebrew para atualizar o cask"
    log_output "  • Linux: Usa Snap para atualizar o pacote"
}

# Main update function
update_nordpass() {
    # Check if installed
    if ! check_installation; then
        log_error "$NORDPASS_NAME não está instalado. Use 'susa setup nordpass install' para instalar."
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"

    log_info "Atualizando $NORDPASS_NAME..."

    # Update based on OS
    if is_mac; then
        update_nordpass_macos
    else
        update_nordpass_linux
    fi

    local update_result=$?

    if [ $update_result -eq 0 ]; then
        # Verify update
        if check_installation; then
            local new_version=$(get_current_version)

            # Update version in lock file
            register_or_update_software_in_lock "$COMMAND_NAME" "$new_version"

            if [ "$current_version" = "$new_version" ]; then
                log_info "$NORDPASS_NAME já estava na versão mais recente ($new_version)"
            else
                log_success "$NORDPASS_NAME atualizado com sucesso para versão $new_version!"
            fi
        else
            log_error "Falha na atualização do $NORDPASS_NAME"
            return 1
        fi
    else
        return $update_result
    fi
}

# Main execution
main() {
    update_nordpass
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
