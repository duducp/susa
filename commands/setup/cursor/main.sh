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
    log_output "  --info          Mostra informações do Cursor instalado"
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Cursor é um editor de código moderno com inteligência artificial integrada."
    log_output "  Baseado no VS Code, oferece recursos avançados de completação e geração"
    log_output "  de código usando IA, aumentando significativamente a produtividade."
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Editor baseado no VS Code com UI familiar"
    log_output "  • IA integrada para completação inteligente de código"
    log_output "  • Chat com IA sobre seu código e projetos"
    log_output "  • Refatoração e geração de código com IA"
    log_output "  • Compatível com extensões do VS Code"
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
                log_output "Use ${LIGHT_CYAN}susa setup cursor --help${NC} para ver opções disponíveis"
                exit 1
                ;;
        esac
    done

    # If no arguments, show help
    display_help
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
