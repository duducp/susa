#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/os.sh"

# Source utils
UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"

source "$UTILS_DIR/common.sh"
source "$UTILS_DIR/install.sh"

# Constants
VSCODE_NAME="Visual Studio Code"
VSCODE_REPO="microsoft/vscode"
VSCODE_BIN_NAME="code"
VSCODE_HOMEBREW_CASK="visual-studio-code"
VSCODE_APT_KEY_URL="https://packages.microsoft.com/keys/microsoft.asc"
VSCODE_APT_REPO="https://packages.microsoft.com/repos/code"
VSCODE_RPM_KEY_URL="https://packages.microsoft.com/keys/microsoft.asc"
VSCODE_RPM_REPO_URL="https://packages.microsoft.com/yumrepos/vscode"
VSCODE_DEB_PACKAGE="code"
VSCODE_RPM_PACKAGE="code"
VSCODE_ARCH_AUR="visual-studio-code-bin"
VSCODE_ARCH_COMMUNITY="code"

# Help function
show_help() {
    show_description
    log_output ""
    show_usage
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Visual Studio Code é um editor de código-fonte desenvolvido pela Microsoft."
    log_output "  Gratuito e open-source, oferece depuração integrada, controle Git,"
    log_output "  syntax highlighting, IntelliSense, snippets e refatoração de código."
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup vscode install              # Instala o VS Code"
    log_output "  susa setup vscode install -v           # Instala com saída detalhada"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  O VS Code estará disponível no menu de aplicativos ou via:"
    log_output "    code                    # Abre o editor"
    log_output "    code arquivo.txt        # Abre arquivo específico"
    log_output "    code pasta/             # Abre pasta como workspace"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • IntelliSense (autocompletar inteligente)"
    log_output "  • Depurador integrado"
    log_output "  • Controle Git nativo"
    log_output "  • Extensões e temas"
    log_output "  • Terminal integrado"
    log_output "  • Remote Development"
}

# Main installation function
install_vscode() {
    if check_installation; then
        log_info "VS Code $(get_current_version) já está instalado."
        exit 0
    fi

    log_info "Iniciando instalação do VS Code..."

    # Detect OS and install
    case "$OS_TYPE" in
        macos)
            install_vscode_macos
            ;;
        debian | fedora)
            install_vscode_linux
            ;;
        *)
            log_error "Sistema operacional não suportado: $OS_TYPE"
            return 1
            ;;
    esac

    local install_result=$?

    if [ $install_result -eq 0 ]; then
        if check_installation; then
            local installed_version=$(get_current_version)
            register_or_update_software_in_lock "$COMMAND_NAME" "$installed_version"

            log_success "VS Code $installed_version instalado com sucesso!"
            log_output ""
            log_output "Próximos passos:"
            log_output "  1. Execute: ${LIGHT_CYAN}code${NC} para abrir o editor"
            log_output "  2. Instale extensões: Ctrl/Cmd+Shift+X"
            log_output "  3. Use ${LIGHT_CYAN}susa setup vscode install --help${NC} para mais informações"
            log_output ""
            log_output "${LIGHT_GREEN}Dica:${NC} Explore extensões em https://marketplace.visualstudio.com"
        else
            log_error "VS Code foi instalado mas não está disponível no PATH"
            return 1
        fi
    else
        return $install_result
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
            --info)
                show_software_info "$VSCODE_BIN_NAME"
                exit 0
                ;;
            --get-current-version)
                get_current_version
                exit 0
                ;;
            --get-latest-version)
                get_latest_version
                exit 0
                ;;
            --check-installation)
                check_installation
                exit $?
                ;;
            --uninstall)
                action="uninstall"
                shift
                ;;
            -y | --yes)
                SKIP_CONFIRM=true
                shift
                ;;
            -u | --upgrade)
                action="update"
                shift
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Execute action
    case "$action" in
        install)
            install_vscode
            ;;
        update)
            update_vscode
            ;;
        uninstall)
            uninstall_vscode
            ;;
        *)
            log_error "Ação desconhecida: $action"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
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
        *)
            log_error "Opção desconhecida: $1"
            show_usage
            exit 1
            ;;
    esac
done

install_vscode
