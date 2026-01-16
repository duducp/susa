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
    log_output "${LIGHT_GREEN}Comandos:${NC}"
    log_output "  info              Mostra informações sobre o cache"
    log_output "  refresh           Força atualização do cache"
    log_output "  clear             Limpa o cache"
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output ""
    log_output "${LIGHT_GREEN}Descrição:${NC}"
    log_output "  O sistema de cache mantém os dados do arquivo susa.lock em memória"
    log_output "  para acelerar drasticamente o tempo de inicialização do CLI."
    log_output ""
    log_output "  O cache é atualizado automaticamente quando:"
    log_output "  • O arquivo susa.lock é modificado"
    log_output "  • O comando 'susa self lock' é executado"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa self cache info        # Mostra status do cache"
    log_output "  susa self cache refresh     # Força atualização do cache"
    log_output "  susa self cache clear       # Remove o cache"
    log_output ""
}

# ============================================================
# Main
# ============================================================

main() {
    local command="${1:-}"

    if [ -z "$command" ] || [ "$command" = "-h" ] || [ "$command" = "--help" ]; then
        show_help
        exit 0
    fi

    case "$command" in
        info)
            log_info "Informações do Cache:"
            echo ""
            cache_info
            ;;
        refresh)
            log_info "Atualizando cache..."
            cache_refresh
            log_success "Cache atualizado com sucesso!"
            ;;
        clear)
            log_info "Limpando cache..."
            cache_clear
            log_success "Cache removido com sucesso!"
            ;;
        *)
            log_error "Comando desconhecido: $command"
            echo "Use 'susa self cache --help' para ver os comandos disponíveis"
            exit 1
            ;;
    esac
}

main "$@"
