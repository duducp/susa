#!/usr/bin/env zsh

UTILS_DIR="$(dirname "$0")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$UTILS_DIR/common.sh"

# Main function
main() {
    log_info "Atualizando Mise..."

    # Check if Mise is installed
    if ! check_installation; then
        log_error "Mise não está instalado. Use ${LIGHT_CYAN}susa setup mise install${NC} para instalar."
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"

    # Update using Mise's built-in self-update command
    log_info "Executando atualização do Mise..."
    if $MISE_BIN_NAME self-update --yes 2>&1 | while read -r line; do log_debug "mise: $line"; done; then
        log_debug "Comando de atualização executado com sucesso"
    else
        log_error "Falha ao atualizar o Mise"
        return 1
    fi

    # Verify update
    if check_installation; then
        local new_version=$(get_current_version)
        if [ "$current_version" = "$new_version" ]; then
            log_info "Mise já está na versão mais recente ($current_version)"
        else
            log_success "Mise atualizado de $current_version para $new_version!"
            register_or_update_software_in_lock "$COMMAND_NAME" "$new_version"
            log_debug "Atualização concluída com sucesso"
        fi
        return 0
    else
        log_error "Falha na atualização do Mise"
        return 1
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
