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
    log_output "  Exibe informações detalhadas sobre o cache do CLI:"
    log_output "  • Status do cache (ativo/inativo)"
    log_output "  • Tamanho do arquivo de cache"
    log_output "  • Data da última atualização"
    log_output "  • Número de categorias e comandos em cache"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplo:${NC}"
    log_output "  susa self cache info"
}

# ============================================================
# Main
# ============================================================

main() {
    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        show_help
        exit 0
    fi

    log_info "Informações do Cache:"
    echo ""
    cache_info
}

main "$@"
