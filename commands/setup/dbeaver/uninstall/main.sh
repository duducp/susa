#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/flatpak.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"
source "$UTILS_DIR/uninstall.sh"

SKIP_CONFIRM=false

# Help function
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  -y, --yes         Pula confirmação"
    log_output ""
    log_output "${LIGHT_GREEN}O que faz:${NC}"
    log_output "  Remove completamente o DBeaver do sistema,"
    log_output "  incluindo pacotes e repositórios."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup dbeaver uninstall        # Desinstala com confirmação"
    log_output "  susa setup dbeaver uninstall -y     # Desinstala sem confirmação"
}

# Uninstall DBeaver
uninstall_dbeaver() {
    log_info "Desinstalando DBeaver..."

    if ! check_installation; then
        log_info "DBeaver não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)
    log_debug "Versão a ser removida: $current_version"

    # Confirm uninstallation
    log_output ""
    if [ "$SKIP_CONFIRM" = false ]; then
        log_output "${YELLOW}Deseja realmente desinstalar o DBeaver $current_version? (s/N)${NC}"
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    # Uninstall based on OS
    case "$OS_TYPE" in
        macos)
            uninstall_dbeaver_macos
            ;;
        *)
            uninstall_dbeaver_linux
            ;;
    esac

    # Verify uninstallation
    if ! check_installation; then
        remove_software_in_lock "$COMMAND_NAME"
        log_success "DBeaver desinstalado com sucesso!"
    else
        log_error "Falha ao desinstalar DBeaver completamente"
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
                log_error "Opção inválida: $1"
                log_output "Use -h ou --help para ver as opções disponíveis"
                exit 1
                ;;
        esac
    done

    # Execute uninstallation
    uninstall_dbeaver
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
