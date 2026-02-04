#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"

# Get utilities directory
UTILS_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../utils"
source "$UTILS_DIR/common.sh"

# Global variables
SKIP_CONFIRM=false

# Help function
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -y, --yes    Pula confirmação de desinstalação"
    log_output ""
    log_output "${LIGHT_GREEN}Nota:${NC}"
    log_output "  Remove o Tilix do sistema via gerenciador de pacotes."
    log_output "  Ao final, perguntará se deseja remover também as configurações de usuário."
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

    # Verify it's Linux
    if [[ "$(uname -s)" != "Linux" ]]; then
        log_error "Tilix só está disponível para Linux"
        exit 1
    fi

    log_info "Desinstalando Tilix..."

    local pkg_manager=$(detect_package_manager)
    log_debug "Gerenciador de pacotes detectado: $pkg_manager"

    # Check if Tilix is installed
    if ! check_installation; then
        log_warning "Tilix não está instalado via gerenciador de pacotes"
        log_info "Nada a fazer"
        return 0
    fi

    local version=$(get_current_version)
    log_debug "Versão a ser removida: $version"

    # Confirm uninstallation
    if [ "$SKIP_CONFIRM" = false ]; then
        echo ""
        log_output "${YELLOW}Deseja realmente desinstalar o Tilix $version? (s/N)${NC}"
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    # Uninstall Tilix
    uninstall_tilix_package "$pkg_manager" "$SKIP_CONFIRM"

    # Verify removal
    if ! check_installation; then
        log_success "Tilix desinstalado com sucesso"
        remove_software_in_lock "$COMMAND_NAME"
    else
        log_warning "Tilix removido do gerenciador de pacotes, mas executável ainda encontrado"
    fi

    # Clean up user configurations
    remove_user_configurations
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
