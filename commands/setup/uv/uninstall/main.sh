#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/shell.sh"

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
    log_output "  Remove os binários uv e uvx de ~/.local/bin."
    log_output "  Oferece opção de remover também:"
    log_output "    • Ferramentas instaladas (ruff, black, mypy, etc)"
    log_output "    • Cache do UV"
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

    log_info "Desinstalando UV..."

    # Check if UV is installed
    if ! check_installation; then
        log_warning "UV não está instalado"
        return 0
    fi

    local version=$(get_current_version)
    log_debug "Versão a ser removida: $version"

    # Confirm uninstallation
    if [ "$SKIP_CONFIRM" = false ]; then
        echo ""
        log_output "${YELLOW}Deseja realmente desinstalar o UV $version? (s/N)${NC}"
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    # Remove binaries
    remove_uv_binaries

    # Remove data (installed tools)
    remove_uv_data "$SKIP_CONFIRM"

    # Verify removal
    if ! check_installation; then
        log_success "UV desinstalado com sucesso!"
        remove_software_in_lock "$COMMAND_NAME"

        local shell_config=$(detect_shell_config)
        echo ""
        log_info "Reinicie o terminal ou execute: source $shell_config"
    else
        log_warning "UV removido, mas executável ainda encontrado no PATH"
        if check_installation; then
            local uv_path=$(command -v uv 2> /dev/null || echo "desconhecido")
            log_debug "Pode ser necessário remover manualmente de: $uv_path"
        fi
    fi

    # Remove cache
    remove_uv_cache "$SKIP_CONFIRM"
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
