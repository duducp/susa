#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# Source libraries
UTILS_DIR="$(dirname "$0")/../utils"
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"
source "$UTILS_DIR/uninstall.sh"

SKIP_CONFIRM=false

# Show help
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  -y, --yes         Pula confirmação"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplo:${NC}"
    log_output "  susa setup postman uninstall              # Desinstala o Postman"
    log_output "  susa setup postman uninstall -y           # Desinstala sem confirmação"
}

# Main function
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
                show_usage "[opções]"
                exit 1
                ;;
        esac
    done

    log_info "Desinstalando Postman..."

    if ! check_installation; then
        log_warning "$POSTMAN_NAME não está instalado"
        return 0
    fi

    local current_version=$(get_current_version 2> /dev/null || echo "desconhecida")

    if [ "$SKIP_CONFIRM" = false ]; then
        log_output ""
        log_output "${YELLOW}Deseja realmente desinstalar o Postman $current_version? (s/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    if is_mac; then
        uninstall_postman_macos
    else
        uninstall_postman_linux
    fi

    log_success "$POSTMAN_NAME desinstalado com sucesso!"

    # Remove from lock file
    remove_software_in_lock "$COMMAND_NAME"
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
