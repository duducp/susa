#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"

# Get utilities directory
UTILS_DIR="$(dirname "$(readlink -f "$0")")/utils"
source "$UTILS_DIR/common.sh"

# Help function
show_complement_help() {
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Sublime Text é um editor de texto sofisticado para código, markup e prosa."
    log_output "  Conhecido por sua velocidade, interface limpa e recursos poderosos como"
    log_output "  múltiplos cursores, busca avançada, e extensa biblioteca de plugins."
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Múltiplos cursores e seleções"
    log_output "  • Command Palette para acesso rápido"
    log_output "  • Goto Anything (Ctrl/Cmd+P)"
    log_output "  • Distraction Free Mode"
    log_output "  • Syntax Highlighting avançado"
    log_output "  • Package Control para plugins"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  O Sublime Text estará disponível no menu de aplicativos ou via:"
    log_output "    ${LIGHT_CYAN}subl${NC}                    # Abre o editor"
    log_output "    ${LIGHT_CYAN}subl arquivo.txt${NC}        # Abre arquivo específico"
    log_output "    ${LIGHT_CYAN}subl pasta/${NC}             # Abre pasta como projeto"
    log_output ""
    log_output "${LIGHT_GREEN}Dica:${NC} Explore os temas e plugins em https://packagecontrol.io"
}

# Main function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --info)
                show_software_info "subl"
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Show help if no arguments
    show_usage
    exit 0
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
