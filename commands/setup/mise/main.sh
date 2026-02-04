#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/shell.sh"
source "$UTILS_DIR/common.sh"

# Show additional info in category listing
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  --info          Mostra informações da instalação do Mise"
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Mise (anteriormente rtx) é um gerenciador de versões de ferramentas"
    log_output "  de desenvolvimento polyglot, escrito em Rust. É compatível com ASDF,"
    log_output "  mas oferece melhor performance e recursos adicionais como task runner."
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Compatível com plugins do ASDF"
    log_output "  • Performance superior (escrito em Rust)"
    log_output "  • Suporte a arquivos legados (.tool-versions, .node-version, etc)"
    log_output "  • Task runner integrado"
    log_output "  • Gerenciamento de variáveis de ambiente"
    log_output ""
    log_output "${LIGHT_GREEN}Próximos passos (após instalação):${NC}"
    log_output "  ${LIGHT_CYAN}mise list${NC}                     # Listar ferramentas instaladas"
    log_output "  ${LIGHT_CYAN}mise doctor${NC}                   # Verificar instalação do Mise"
    log_output "  ${LIGHT_CYAN}mise use --global go@1.25.6${NC}  # Instalar e usar Go globalmente"
    log_output "  ${LIGHT_CYAN}mise use node@20${NC}              # Usar Node 20 no diretório atual"
    log_output "  ${LIGHT_CYAN}mise ls-remote go${NC}             # Listar versões disponíveis de Go"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplo de uso com Go:${NC}"
    log_output "  Para o Go funcionar corretamente, adicione ao seu shell:"
    log_output "    ${DIM}export GOPATH=\"\$HOME/go\"${NC}"
    log_output "    ${DIM}export PATH=\"\$GOPATH/bin:\$PATH\"${NC}"
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
                log_output "Use ${LIGHT_CYAN}susa setup mise --help${NC} para ver opções disponíveis"
                exit 1
                ;;
        esac
    done

    # If no arguments, show help
    display_help
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
