#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"

# Source utils
UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"

source "$UTILS_DIR/common.sh"
source "$UTILS_DIR/uninstall.sh"

# Constants
VSCODE_NAME="Visual Studio Code"
VSCODE_BIN_NAME="code"
VSCODE_HOMEBREW_CASK="visual-studio-code"

SKIP_CONFIRM=false

# Help function
show_help() {
    show_description
    log_output ""
    show_usage
    log_output ""
    log_output "${LIGHT_GREEN}O que faz:${NC}"
    log_output "  Remove completamente o Visual Studio Code do sistema,"
    log_output "  incluindo pacotes e repositórios (opcional: configurações)."
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  -y, --yes         Pula confirmação e remove configurações"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
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
    case "$OS_TYPE" in
        macos)
            if command -v brew &> /dev/null; then
                log_info "Removendo VS Code via Homebrew..."
                brew uninstall --cask $VSCODE_HOMEBREW_CASK 2> /dev/null || log_debug "VS Code não instalado via Homebrew"
            fi
            ;;
        debian | fedora)
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
            esac
            ;;
    esac

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
            -h | --help)
                show_help
                exit 0
                ;;
            -v | --verbose)
                log_debug "Modo verbose ativado"
                export DEBUG=true
                shift
                ;;
            -q | --quiet)
                export SILENT=true
                shift
                ;;
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

# Execute main function
main "$@"
