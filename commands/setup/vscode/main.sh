#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"

# Source utils
UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/utils"

source "$UTILS_DIR/common.sh"

# Constants
VSCODE_NAME="Visual Studio Code"
VSCODE_REPO="microsoft/vscode"
VSCODE_BIN_NAME="code"

# Show additional info in category listing
show_complement_help() {
    log_output ""
    log_output "${LIGHT_GREEN}Comandos de informação:${NC}"
    log_output "  ${LIGHT_CYAN}susa setup vscode --info${NC}                    Mostra informações do VS Code instalado"
    log_output "  ${LIGHT_CYAN}susa setup vscode --check-installation${NC}      Verifica se VS Code está instalado"
    log_output "  ${LIGHT_CYAN}susa setup vscode --get-current-version${NC}     Exibe versão instalada"
    log_output "  ${LIGHT_CYAN}susa setup vscode --get-latest-version${NC}      Exibe versão mais recente disponível"
}

# Help function
show_help() {
    log_output "${BOLD}${LIGHT_BLUE}Visual Studio Code${NC}"
    log_output ""
    log_output "Gerenciar instalação e configurações do VS Code"
    log_output ""
    log_output "${LIGHT_GREEN}Uso:${NC}"
    log_output "  susa setup vscode <comando> [opções]"
    log_output "  susa setup vscode [opções]"
    log_output ""
    log_output "${LIGHT_GREEN}Comandos disponíveis:${NC}"
    log_output "  install      Instala o VS Code"
    log_output "  update       Atualiza o VS Code para versão mais recente"
    log_output "  uninstall    Remove o VS Code do sistema"
    log_output "  backup       Gerencia backups das configurações"
    log_output ""
    log_output "${LIGHT_GREEN}Opções de informação:${NC}"
    log_output "  --info                    Mostra informações do VS Code instalado"
    log_output "  --check-installation      Verifica se VS Code está instalado"
    log_output "  --get-current-version     Exibe versão instalada"
    log_output "  --get-latest-version      Exibe versão mais recente disponível"
    log_output "  -h, --help                Mostra esta mensagem de ajuda"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup vscode install             # Instala o VS Code"
    log_output "  susa setup vscode update              # Atualiza o VS Code"
    log_output "  susa setup vscode --info              # Mostra info da instalação"
    log_output "  susa setup vscode --get-current-version  # Mostra versão instalada"
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
            *)
                log_error "Opção desconhecida: $1"
                log_output ""
                log_output "Use ${LIGHT_CYAN}susa setup vscode --help${NC} para ver opções disponíveis"
                exit 1
                ;;
        esac
    done

    # If no arguments, show help
    show_help
}

# Execute main function
main "$@"
