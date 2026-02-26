#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# List available Cursor backups
# Source libraries
UTILS_DIR="$(dirname "$0")/../../utils"
source "$LIB_DIR/os.sh"
source "$UTILS_DIR/common.sh"

# Default backup directory
DEFAULT_BACKUP_DIR="$HOME/.susa/backups/cursor"
BACKUP_DIR="${CURSOR_BACKUP_DIR:-$DEFAULT_BACKUP_DIR}"

# Show help
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  --dir <diretório>       Diretório onde estão os backups"
    log_output "  --detailed              Mostra informações detalhadas de cada backup"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup cursor backup list                    # Lista backups disponíveis"
    log_output "  susa setup cursor backup list --detailed         # Lista com detalhes"
    log_output "  susa setup cursor backup list --dir /caminho     # Lista de diretório específico"
}

# List available backups
list_backups() {
    local show_details="${1:-false}"

    # Check if backup directory exists
    if [ ! -d "$BACKUP_DIR" ]; then
        log_debug "Diretório de backups não encontrado: $BACKUP_DIR"
        log_info "Nenhum backup foi criado ainda"
        return 0
    fi

    # Find all backup files
    local -a backups=()
    while IFS= read -r file; do
        backups+=("$file")
    done < <(find "$BACKUP_DIR" -maxdepth 1 -name "*.tar.gz" -type f 2> /dev/null | sort -r)

    if [ ${#backups[@]} -eq 0 ]; then
        log_info "Nenhum backup encontrado em: $BACKUP_DIR"
        return 0
    fi

    log_output "${LIGHT_GREEN}Backups disponíveis:${NC}"
    log_output ""

    for backup_file in "${backups[@]}"; do
        local backup_name=$(basename "$backup_file" .tar.gz)
        local backup_size=$(du -h "$backup_file" | cut -f1)
        local backup_date=$(stat -c %y "$backup_file" 2> /dev/null | cut -d' ' -f1,2 | cut -d'.' -f1 || stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$backup_file")

        log_output "  ${CYAN}$backup_name${NC}"
        log_output "    Tamanho: $backup_size"
        log_output "    Criado: $backup_date"

        if [ "$show_details" = "true" ]; then
            # Extract and show backup metadata
            local temp_info_dir=$(mktemp -d)
            tar -xzf "$backup_file" -C "$temp_info_dir" cursor-backup/backup-info.json 2> /dev/null || true

            if [ -f "$temp_info_dir/cursor-backup/backup-info.json" ]; then
                local cursor_version=$(grep -o '"cursor_version":\s*"[^"]*"' "$temp_info_dir/cursor-backup/backup-info.json" | cut -d'"' -f4)
                local os_info=$(grep -o '"os":\s*"[^"]*"' "$temp_info_dir/cursor-backup/backup-info.json" | cut -d'"' -f4)

                if [ -n "$cursor_version" ]; then
                    log_output "    Versão Cursor: $cursor_version"
                fi
                if [ -n "$os_info" ]; then
                    log_output "    Sistema: $os_info"
                fi

                # Show what's included
                local includes=$(grep -o '"includes":\s*\[[^\]]*\]' "$temp_info_dir/cursor-backup/backup-info.json")
                if [ -n "$includes" ]; then
                    log_output "    Inclui: $(echo "$includes" | grep -o '"[^"]*"' | tr -d '"' | grep -v includes | tr '\n' ', ' | sed 's/,$//')"
                fi
            fi

            rm -rf "$temp_info_dir"
        fi

        log_output ""
    done

    log_output "${LIGHT_GREEN}Total:${NC} ${#backups[@]} backup(s)"
    log_output ""
    log_output "${LIGHT_GREEN}Para restaurar um backup:${NC}"
    log_output "  susa setup cursor backup restore <nome-do-backup>"
}

# Main function
main() {
    local show_details="false"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dir)
                BACKUP_DIR="$2"
                shift 2
                ;;
            --detailed)
                show_details="true"
                shift
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_usage "[opções]"
                exit 1
                ;;
        esac
    done

    # List backups
    list_backups "$show_details"
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
