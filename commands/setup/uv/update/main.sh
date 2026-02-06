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
    log_output "  Utiliza o comando nativo ${LIGHT_CYAN}uv self update${NC} para atualização."
    log_output "  O UV verifica automaticamente novas versões e atualiza."
}

# Main update function
main() {
    log_info "Atualizando UV..."

    # Check if UV is installed
    if ! check_installation; then
        log_error "UV não está instalado"
        echo ""
        log_output "${YELLOW}Para instalar, execute:${NC} ${LIGHT_CYAN}susa setup uv install${NC}"
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"

    # Update using UV's built-in self update command
    log_info "Executando atualização do UV..."

    if uv self update 2>&1 | while read -r line; do log_debug "uv: $line"; done; then
        log_debug "Comando de atualização executado com sucesso"
    else
        log_error "Falha ao atualizar o UV"
        return 1
    fi

    # Verify update
    if check_installation; then
        local new_version=$(get_current_version)

        if [ "$current_version" = "$new_version" ]; then
            log_info "UV já está na versão mais recente ($current_version)"
        else
            log_success "UV atualizado de $current_version para $new_version!"
            register_or_update_software_in_lock "$COMMAND_NAME" "$new_version"
            log_debug "Atualização concluída com sucesso"
        fi

        return 0
    else
        log_error "Falha na atualização do UV"
        return 1
    fi
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
