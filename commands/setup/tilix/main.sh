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
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  --info          Mostra informações da instalação"
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Tilix é um emulador de terminal avançado para Linux usando GTK+ 3."
    log_output "  Oferece recursos como tiles (painéis lado a lado), notificações,"
    log_output "  transparência, temas personalizáveis e muito mais."
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Tiles (painéis lado a lado)"
    log_output "  • Transparência e efeitos visuais"
    log_output "  • Drag and drop de arquivos"
    log_output "  • Hyperlinks clicáveis"
    log_output "  • Temas e esquemas de cores"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  O Tilix estará disponível no menu de aplicativos."
    log_output "  Para configurá-lo como terminal padrão:"
    log_output "    ${LIGHT_CYAN}sudo update-alternatives --config x-terminal-emulator${NC}"
}

# Main function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --info)
                show_software_info "tilix"
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
