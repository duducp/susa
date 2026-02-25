#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/utils"
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/shell.sh"
source "$UTILS_DIR/common.sh"

# Optional - Additional information in help
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  --info          Mostra status da instalação"
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  $TOOLBOX_NAME é um aplicativo que facilita o gerenciamento"
    log_output "  de todas as IDEs da JetBrains (IntelliJ IDEA, PyCharm, WebStorm,"
    log_output "  GoLand, etc.) a partir de uma única interface."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup jetbrains-toolbox install     # Instala o $TOOLBOX_NAME"
    log_output "  susa setup jetbrains-toolbox update      # Atualiza o $TOOLBOX_NAME"
    log_output "  susa setup jetbrains-toolbox uninstall   # Desinstala o $TOOLBOX_NAME"
    log_output "  susa setup jetbrains-toolbox --info      # Mostra status da instalação"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  O JetBrains Toolbox será iniciado automaticamente."
    log_output "  Use-o para instalar e gerenciar suas IDEs JetBrains."
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Gerenciamento centralizado de IDEs JetBrains"
    log_output "  • Atualizações automáticas"
    log_output "  • Múltiplas versões da mesma IDE"
    log_output "  • Importação de configurações"
    log_output "  • Suporte a projetos recentes"
}

# Optional - Additional information
show_additional_info() {
    log_output "${LIGHT_GREEN}IDEs disponíveis:${NC}"
    log_output "  IntelliJ IDEA (Java/Kotlin)"
    log_output "  PyCharm (Python)"
    log_output "  WebStorm (JavaScript/TypeScript)"
    log_output "  PhpStorm (PHP)"
    log_output "  GoLand (Go)"
    log_output "  RubyMine (Ruby)"
    log_output "  CLion (C/C++)"
    log_output "  Rider (.NET)"
    log_output "  DataGrip (Database)"
    log_output "  Android Studio (Android)"
}

# Main function for --info flag
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --info)
                show_software_info "$TOOLBOX_BIN_NAME" "$TOOLBOX_BIN_NAME"
                show_additional_info
                exit 0
                ;;
            -h | --help)
                # Help is handled by the CLI framework
                exit 0
                ;;
            *)
                log_error "Opção inválida: $1"
                log_output "Use 'susa setup jetbrains-toolbox --help' para ver opções disponíveis"
                exit 1
                ;;
        esac
    done

    # If no action specified, show help
    log_output "Use 'susa setup jetbrains-toolbox --help' para ver comandos disponíveis"
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
