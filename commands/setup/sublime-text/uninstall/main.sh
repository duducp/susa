#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"

# Get utilities directory
UTILS_DIR="$(dirname "$(readlink -f "$0")")/../utils"
source "$UTILS_DIR/common.sh"

# Global variables
SKIP_CONFIRM=false

# Help function
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -y, --yes    Pula confirmação de desinstalação"
    log_output ""
    log_output "${LIGHT_GREEN}Nota:${NC}"
    log_output "  Remove o Sublime Text do sistema."
    log_output "  Ao final, perguntará se deseja remover também as configurações e pacotes."
}

# Main uninstall function
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
                show_usage
                exit 1
                ;;
        esac
    done

    log_info "Desinstalando Sublime Text..."

    # Check if Sublime Text is installed
    if ! check_installation; then
        log_info "Sublime Text não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)
    log_debug "Versão a ser removida: $current_version"

    # Confirm uninstall
    log_output ""
    if [ "$SKIP_CONFIRM" = false ]; then
        log_output "${YELLOW}Deseja realmente desinstalar o Sublime Text $current_version? (s/N)${NC}"
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    # Uninstall based on OS
    if is_mac; then
        uninstall_sublime_macos
    else
        uninstall_sublime_linux
    fi

    # Verify uninstallation
    if ! check_installation; then
        # Mark as uninstalled in lock file
        remove_software_in_lock "$COMMAND_NAME"

        log_success "Sublime Text desinstalado com sucesso!"
    else
        log_error "Falha ao desinstalar Sublime Text completamente"
        return 1
    fi

    # Ask about configuration removal
    remove_sublime_data
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
