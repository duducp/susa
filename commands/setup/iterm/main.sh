#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/utils"
source "$LIB_DIR/internal/installations.sh"
source "$UTILS_DIR/common.sh"

# Optional - Additional information in help
show_complement_help() {
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  $ITERM_NAME é um substituto para o Terminal do macOS com recursos"
    log_output "  avançados como split panes, busca, autocompletar, histórico,"
    log_output "  notificações e muito mais."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup iterm install              # Instala o $ITERM_NAME"
    log_output "  susa setup iterm update               # Atualiza o $ITERM_NAME"
    log_output "  susa setup iterm uninstall            # Desinstala o $ITERM_NAME"
    log_output "  susa setup iterm --info               # Mostra status da instalação"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  O iTerm2 estará disponível na pasta Aplicativos."
    log_output "  Configure-o como terminal padrão em: Preferências do Sistema > Geral"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Split panes horizontais e verticais"
    log_output "  • Busca em todo o histórico"
    log_output "  • Autocompletar inteligente"
    log_output "  • Suporte a temas e cores"
    log_output "  • Triggers e notificações"
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --info)
                show_software_info "iterm" "$ITERM_BIN_NAME"
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                log_output "Use ${LIGHT_CYAN}susa setup iterm --help${NC} para ver opções"
                exit 1
                ;;
        esac
    done

    # If no arguments, show help
    display_help
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
