#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# Restore backup of Cursor configurations
# Source libraries
UTILS_DIR="$(dirname "$0")/../../utils"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/flatpak.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

# Default backup directory
DEFAULT_BACKUP_DIR="$HOME/.susa/backups/cursor"
BACKUP_DIR="${CURSOR_BACKUP_DIR:-$DEFAULT_BACKUP_DIR}"

# Show help
show_complement_help() {
    log_output "${LIGHT_GREEN}Uso:${NC}"
    log_output "  susa setup cursor backup restore <nome-do-backup> [opções]"
    log_output ""
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  --dir <diretório>       Diretório onde estão os backups"
    log_output "  --force                 Restaurar sem confirmação"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup cursor backup restore cursor-backup-20260226-143050    # Restaura backup específico"
    log_output "  susa setup cursor backup restore my-backup --force                # Restaura sem confirmação"
    log_output ""
    log_output "${LIGHT_GREEN}Nota:${NC}"
    log_output "  As configurações atuais serão substituídas. Considere fazer um backup"
    log_output "  antes de restaurar."
}

# Restore backup of Cursor configurations
restore_backup() {
    local backup_name="$1"
    local force="${2:-false}"

    # Check if Cursor is installed
    if ! check_installation; then
        log_error "Cursor não está instalado"
        log_info "Use: susa setup cursor install"
        return 1
    fi

    # Get configuration paths
    if ! get_cursor_config_paths; then
        return 1
    fi

    local backup_archive="$BACKUP_DIR/$backup_name.tar.gz"

    # Check if backup exists
    if [ ! -f "$backup_archive" ]; then
        log_error "Backup não encontrado: $backup_archive"
        log_info "Use 'susa setup cursor backup list' para ver backups disponíveis"
        return 1
    fi

    # Extract backup info
    local temp_info_dir=$(mktemp -d)
    tar -xzf "$backup_archive" -C "$temp_info_dir" cursor-backup/backup-info.json 2> /dev/null || true

    if [ -f "$temp_info_dir/cursor-backup/backup-info.json" ]; then
        log_info "Informações do backup:"
        log_output "$(cat "$temp_info_dir/cursor-backup/backup-info.json" | grep -E '(created_at|cursor_version|os)' | sed 's/^/  /')"
        log_output ""
    fi

    rm -rf "$temp_info_dir"

    # Confirm restoration
    if [ "$force" != "true" ]; then
        gum_confirm "Tem certeza que deseja restaurar este backup? As configurações atuais serão substituídas." || {
            log_info "Restauração cancelada"
            return 0
        }
    fi

    log_info "Restaurando backup do Cursor..."
    log_debug "De: $backup_archive"
    log_debug "Para: $CURSOR_CONFIG_DIR"

    # Create temporary directory for extraction
    local temp_restore_dir=$(mktemp -d)

    # Extract backup
    log_info "Extraindo backup..."
    tar -xzf "$backup_archive" -C "$temp_restore_dir" > /dev/null 2>&1

    local backup_content_dir="$temp_restore_dir/cursor-backup"

    # Restore User settings
    if [ -d "$backup_content_dir/User" ]; then
        log_info "Restaurando configurações do usuário..."
        mkdir -p "$CURSOR_CONFIG_DIR/User"
        cp -r "$backup_content_dir/User"/* "$CURSOR_CONFIG_DIR/User/" 2> /dev/null || true
    fi

    # Restore profiles
    if [ -d "$backup_content_dir/User/profiles" ]; then
        log_info "Restaurando perfis..."
        mkdir -p "$CURSOR_CONFIG_DIR/User/profiles"
        cp -r "$backup_content_dir/User/profiles"/* "$CURSOR_CONFIG_DIR/User/profiles/" 2> /dev/null || true
    fi

    # Restore snippets
    if [ -d "$backup_content_dir/User/snippets" ]; then
        log_info "Restaurando snippets..."
        mkdir -p "$CURSOR_CONFIG_DIR/User/snippets"
        cp -r "$backup_content_dir/User/snippets"/* "$CURSOR_CONFIG_DIR/User/snippets/" 2> /dev/null || true
    fi

    # Restore MCP servers configuration
    if [ -d "$backup_content_dir/User/globalStorage" ]; then
        log_info "Restaurando configuração de MCP Servers..."
        mkdir -p "$CURSOR_CONFIG_DIR/User/globalStorage"
        cp -r "$backup_content_dir/User/globalStorage"/* "$CURSOR_CONFIG_DIR/User/globalStorage/" 2> /dev/null || true
    fi

    # Restore workspace storage
    if [ -d "$backup_content_dir/User/workspaceStorage" ]; then
        log_info "Restaurando workspace storage..."
        mkdir -p "$CURSOR_CONFIG_DIR/User/workspaceStorage"
        cp -r "$backup_content_dir/User/workspaceStorage"/* "$CURSOR_CONFIG_DIR/User/workspaceStorage/" 2> /dev/null || true
    fi

    # Clean up temporary directory
    rm -rf "$temp_restore_dir"

    log_success "✓ Backup restaurado com sucesso!"
    log_output ""
    log_output "${LIGHT_GREEN}Próximos passos:${NC}"
    log_output "  1. Reinicie o Cursor para aplicar as configurações"
    log_output "  2. Verifique se todas as configurações foram restauradas corretamente"
    return 0
}

# Main function
main() {
    local backup_name=""
    local force="false"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dir)
                BACKUP_DIR="$2"
                shift 2
                ;;
            --force)
                force="true"
                shift
                ;;
            -*)
                log_error "Opção desconhecida: $1"
                show_usage "<nome-do-backup> [opções]"
                exit 1
                ;;
            *)
                backup_name="$1"
                shift
                ;;
        esac
    done

    # Check if backup name was provided
    if [ -z "$backup_name" ]; then
        log_error "Nome do backup não especificado"
        show_usage "<nome-do-backup> [opções]"
        exit 1
    fi

    # Restore backup
    restore_backup "$backup_name" "$force"
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
