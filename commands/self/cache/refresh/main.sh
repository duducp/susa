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
    log_output "  Força a atualização do cache do CLI, recarregando os dados"
    log_output "  do arquivo susa.lock em memória."
    log_output ""
    log_output "  Use este comando quando:"
    log_output "  • O arquivo susa.lock foi atualizado manualmente"
    log_output "  • Você suspeita que o cache está desatualizado"
    log_output "  • Após modificações na estrutura de comandos"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplo:${NC}"
    log_output "  susa self cache refresh"
}

# ============================================================
# Main
# ============================================================

main() {
    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        show_help
        exit 0
    fi

    log_info "Atualizando cache..."
    cache_refresh
    log_success "Cache atualizado com sucesso!"
}

main "$@"
