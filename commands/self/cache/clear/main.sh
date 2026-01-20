#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Setup command environment
# Bibliotecas essenciais já carregadas automaticamente

# ============================================================
# Help Function
# ============================================================

show_complement_help() {
    log_output "${LIGHT_GREEN}Argumentos:${NC}"
    log_output "  <cache-name>      Nome do cache a limpar (ex: lock)"
    log_output "  --all             Limpa todos os caches"
    log_output ""
    log_output "${LIGHT_GREEN}Descrição:${NC}"
    log_output "  Remove um cache específico ou todos os caches da memória e disco."
    log_output ""
    log_output "  Os caches serão recriados automaticamente quando necessário."
    log_output ""
    log_output "  Use este comando quando:"
    log_output "  • Você deseja limpar espaço em memória"
    log_output "  • Um cache está corrompido ou causando problemas"
    log_output "  • Para forçar uma recriação completa"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa self cache clear lock        # Limpa apenas o cache do lock"
    log_output "  susa self cache clear --all       # Limpa todos os caches"
}

# ============================================================
# Main
# ============================================================

main() {
    # Parse arguments
    if [ $# -eq 0 ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        show_help
        exit 0
    fi

    local cache_name="$1"

    # Clear all caches
    if [ "$cache_name" = "--all" ]; then
        log_info "Limpando todos os caches..."

        local count=$(cache_clear_all)

        if [ "$count" -gt 0 ]; then
            log_success "✓ $count cache(s) removido(s) com sucesso!"
        else
            log_warning "Nenhum cache encontrado"
        fi
        exit 0
    fi

    # Clear specific cache
    log_info "Limpando cache '$cache_name'..."

    if cache_named_clear "$cache_name" 2> /dev/null; then
        log_success "✓ Cache '$cache_name' removido com sucesso!"
    else
        log_warning "Cache '$cache_name' não existe ou já foi removido"
    fi
}

# Execute main only if not showing help
if [ "${SUSA_SHOW_HELP:-}" != "1" ]; then
    main "$@"
fi
