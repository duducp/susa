#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/snap.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"
source "$UTILS_DIR/uninstall.sh"

SKIP_CONFIRM=false

# Show additional info in command help
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  -y, --yes         Pula confirmação e desinstala automaticamente"
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Remove completamente o NordPass do sistema."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup nordpass uninstall           # Desinstala com confirmação"
    log_output "  susa setup nordpass uninstall -y        # Desinstala sem confirmação"
    log_output ""
    log_output "${LIGHT_GREEN}Comportamento:${NC}"
    log_output "  • macOS: Remove via Homebrew"
    log_output "  • Linux: Remove via Snap"
    log_output ""
    log_output "${YELLOW}Atenção:${NC} Esta ação não pode ser desfeita!"
}

# Main uninstall function
uninstall_nordpass() {
    # Check if installed
    if ! check_installation; then
        log_info "$NORDPASS_NAME não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)

    if [ "$SKIP_CONFIRM" = false ]; then
        log_output ""
        log_output "${YELLOW}Deseja realmente desinstalar o $NORDPASS_NAME $current_version? (s/N)${NC}"
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    log_info "Removendo $NORDPASS_NAME..."

    remove_nordpass_internal

    # Verify uninstallation
    if ! check_installation; then
        # Mark as uninstalled in lock file
        remove_software_in_lock "$COMMAND_NAME"

        log_success "$NORDPASS_NAME desinstalado com sucesso!"
    else
        log_error "Falha ao desinstalar $NORDPASS_NAME completamente"
        return 1
    fi
}

# Main execution
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y | --yes)
                SKIP_CONFIRM=true
                shift
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
        esac
    done

    uninstall_nordpass
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
