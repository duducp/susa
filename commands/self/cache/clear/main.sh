#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Setup command environment
source "$LIB_DIR/logger.sh"
source "$LIB_DIR/internal/cache.sh"

# ============================================================
# Help Function
# ============================================================

show_help() {
    show_description
    log_output ""
    show_usage --no-options
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output ""
    log_output "${LIGHT_GREEN}Descrição:${NC}"
    log_output "  Remove o cache do CLI da memória compartilhada."
    log_output ""
    log_output "  O cache será recriado automaticamente na próxima execução"
    log_output "  do CLI ao carregar os dados do arquivo susa.lock."
    log_output ""
    log_output "  Use este comando quando:"
    log_output "  • Você deseja limpar espaço em memória"
    log_output "  • O cache está corrompido ou causando problemas"
    log_output "  • Para forçar uma recriação completa do cache"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplo:${NC}"
    log_output "  susa self cache clear"
}

# ============================================================
# Main
# ============================================================

main() {
    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        show_help
        exit 0
    fi

    log_info "Limpando cache..."
    cache_clear
    log_success "Cache removido com sucesso!"
}

main "$@"
