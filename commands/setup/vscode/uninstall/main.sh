#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$UTILS_DIR/common.sh"
source "$UTILS_DIR/uninstall.sh"

# Constants
SKIP_CONFIRM=false

# Help function
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  -y, --yes         Pula confirmação e remove configurações"
    log_output ""
    log_output "${LIGHT_GREEN}O que faz:${NC}"
    log_output "  Remove completamente o Visual Studio Code do sistema,"
    log_output "  incluindo pacotes e repositórios (opcional: configurações)."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup vscode uninstall        # Desinstala com confirmação"
    log_output "  susa setup vscode uninstall -y     # Desinstala sem confirmação"
    log_output ""
    log_output "${YELLOW}Atenção:${NC}"
    log_output "  Por padrão, as configurações e extensões são preservadas."
    log_output "  Use -y para removê-las automaticamente ou responda 's' na confirmação."
}

# Uninstall VS Code
uninstall_vscode() {
    log_info "Desinstalando VS Code..."

    if ! check_installation; then
        log_info "VS Code não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)
    log_debug "Versão a ser removida: $current_version"

    # Confirm uninstallation
    log_output ""
    if [ "$SKIP_CONFIRM" = false ]; then
        log_output "${YELLOW}Deseja realmente desinstalar o VS Code $current_version? (s/N)${NC}"
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    # Uninstall based on OS
    if is_mac; then
        if homebrew_is_available; then
            log_info "Removendo VS Code via Homebrew..."
            homebrew_uninstall "$VSCODE_HOMEBREW_CASK" "VS Code" || log_debug "VS Code não instalado via Homebrew"
        else
            log_warning "Homebrew não disponível. VS Code pode estar instalado manualmente."
            log_info "Verifique: /Applications/Visual Studio Code.app"
        fi
    else
        local distro=$(get_distro_id)
        log_debug "Distribuição detectada: $distro"

        case "$distro" in
            ubuntu | debian | pop | linuxmint | elementary)
                uninstall_vscode_debian
                ;;
            fedora | rhel | centos | rocky | almalinux)
                uninstall_vscode_rhel
                ;;
            arch | manjaro | endeavouros)
                uninstall_vscode_arch
                ;;
            *)
                log_error "Sistema Linux não suportado. Suportados: Debian/Ubuntu, Fedora/RHEL, Arch"
                return 1
                ;;
        esac
    fi

    # Verify uninstallation
    if ! check_installation; then
        remove_software_in_lock "$COMMAND_NAME"
        log_success "VS Code desinstalado com sucesso!"
    else
        log_error "Falha ao desinstalar VS Code completamente"
        return 1
    fi

    # Ask about configuration removal
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    if [ "$SKIP_CONFIRM" = false ]; then
        log_output ""
        log_output "${YELLOW}Deseja remover também as configurações e extensões do VS Code? (s/N)${NC}"
        read -r config_response

        if [[ "$config_response" =~ ^[sSyY]$ ]]; then
            remove_vscode_configs "$os_name"
        else
            log_info "Configurações mantidas"
        fi
    else
        remove_vscode_configs "$os_name"
    fi
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
                show_usage
                exit 1
                ;;
        esac
    done

    uninstall_vscode
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
