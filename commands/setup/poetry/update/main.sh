#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$UTILS_DIR/common.sh"

# Main function
main() {
    log_info "Atualizando Poetry..."

    # Check if Poetry is installed
    if ! check_installation; then
        log_error "Poetry não está instalado"
        echo ""
        log_output "${YELLOW}Para instalar, execute:${NC} ${LIGHT_CYAN}susa setup poetry install${NC}"
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"

    # Update Poetry using self update command
    log_info "Executando atualização do Poetry..."

    if poetry self update 2>&1 | while read -r line; do log_debug "poetry: $line"; done; then
        log_debug "Comando de atualização executado com sucesso"
    else
        log_error "Falha ao atualizar o Poetry"
        return 1
    fi

    # Verify update
    if check_installation; then
        local new_version=$(get_current_version)

        if [ "$current_version" = "$new_version" ]; then
            log_info "Poetry já está na versão mais recente ($current_version)"
        else
            # Update version in lock file
            register_or_update_software_in_lock "$COMMAND_NAME" "$new_version"

            log_success "Poetry atualizado de $current_version para $new_version!"
            log_debug "Atualização concluída com sucesso"
        fi

        return 0
    else
        log_error "Falha na atualização do Poetry"
        return 1
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
