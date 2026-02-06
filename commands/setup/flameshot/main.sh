#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/flatpak.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

# Show additional info in category listing
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  --info          Mostra informações do Flameshot instalado"
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Flameshot é uma ferramenta poderosa e simples de captura de tela."
    log_output "  Oferece recursos de anotação, edição e compartilhamento de screenshots"
    log_output "  com interface intuitiva e atalhos de teclado customizáveis."
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Captura de tela com seleção de área"
    log_output "  • Editor de imagens integrado"
    log_output "  • Anotações: setas, linhas, texto, formas"
    log_output "  • Atalhos de teclado customizáveis"
}

# Main function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --info)
                show_software_info
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                log_output ""
                log_output "Use ${LIGHT_CYAN}susa setup flameshot --help${NC} para ver opções disponíveis"
                exit 1
                ;;
        esac
    done

    # If no arguments, show help
    display_help
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
