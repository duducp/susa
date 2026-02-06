#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/utils"
source "$LIB_DIR/internal/installations.sh"
source "$UTILS_DIR/common.sh"

# Optional - Additional information in help
show_complement_help() {
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  $ASDF_NAME é um gerenciador de versões universal que suporta múltiplas"
    log_output "  linguagens de programação através de plugins (Node.js, Python, Ruby,"
    log_output "  Elixir, Java, e muitos outros)."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup asdf install              # Instala o $ASDF_NAME"
    log_output "  susa setup asdf update               # Atualiza o $ASDF_NAME"
    log_output "  susa setup asdf uninstall            # Desinstala o $ASDF_NAME"
    log_output "  susa setup asdf --info               # Mostra status da instalação"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Após a instalação, reinicie o terminal ou execute:"
    log_output "    source ~/.bashrc   (para Bash)"
    log_output "    source ~/.zshrc    (para Zsh)"
    log_output ""
    log_output "${LIGHT_GREEN}Próximos passos:${NC}"
    log_output "  asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git"
    log_output "  asdf install nodejs latest"
    log_output "  asdf global nodejs latest"
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --info)
                show_software_info "asdf" "$ASDF_BIN_NAME"
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                log_output "Use ${LIGHT_CYAN}susa setup asdf --help${NC} para ver opções"
                exit 1
                ;;
        esac
    done

    # If no arguments, show help
    display_help
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
