#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# List available VSCode backups
# Bibliotecas essenciais já carregadas automaticamente

# Default backup directory
DEFAULT_BACKUP_DIR="$HOME/.susa/backups/vscode"
BACKUP_DIR="${VSCODE_BACKUP_DIR:-$DEFAULT_BACKUP_DIR}"

# Show help
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  --dir <dir>       Diretório de backups (padrão: ~/.susa/backups/vscode)"
}

# List available backups
list_backups() {
    log_info "Listando backups disponíveis..."
    log_output ""

    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2> /dev/null)" ]; then
        log_output "Nenhum backup encontrado."
        log_output ""
        log_output "Para criar um backup, use: ${LIGHT_CYAN}susa setup vscode backup create${NC}"
        return 0
    fi

    log_output "${BOLD}Backups disponíveis:${NC}"
    log_output ""

    # Build table data for gum
    local table_data="Nome,Tamanho,Data de Criação"$'\n'

    local count=0
    for backup in "$BACKUP_DIR"/*.tar.gz; do
        if [ -f "$backup" ]; then
            count=$((count + 1))
            local backup_name=$(basename "$backup" .tar.gz)
            local backup_size=$(du -h "$backup" | cut -f1)
            local backup_date=$(date -r "$backup" "+%Y-%m-%d %H:%M:%S" 2> /dev/null || stat -c %y "$backup" 2> /dev/null | cut -d' ' -f1-2)

            table_data+="${backup_name},${backup_size},${backup_date}"$'\n'
        fi
    done

    if [ $count -eq 0 ]; then
        log_output "Nenhum backup encontrado."
    else
        # Render table with gum
        echo "$table_data" | gum_table_csv
        log_output ""
        log_output "${BOLD}Total:${NC} $count backup(s) • ${BOLD}Diretório:${NC} $BACKUP_DIR"
        log_output ""
        log_output "${LIGHT_GREEN}Para restaurar um backup:${NC}"
        log_output "  susa setup vscode backup restore <nome-do-backup>"
    fi
}

# Main function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dir)
                BACKUP_DIR="$2"
                shift 2
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_usage "[opções]"
                exit 1
                ;;
        esac
    done

    # List backups
    list_backups
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
