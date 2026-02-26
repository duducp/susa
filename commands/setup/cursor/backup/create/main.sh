#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# Create backup of Cursor configurations
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
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  --name <nome>           Nome do backup (padrão: cursor-backup-YYYYMMDD-HHMMSS)"
    log_output "  --dir <diretório>       Diretório onde salvar o backup"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup cursor backup create                      # Cria backup com nome automático"
    log_output "  susa setup cursor backup create --name my-backup     # Cria backup com nome específico"
    log_output "  susa setup cursor backup create --dir /caminho       # Salva em diretório específico"
    log_output ""
    log_output "${LIGHT_GREEN}O que é incluído no backup:${NC}"
    log_output "  • Configurações do usuário (settings.json)"
    log_output "  • Keybindings (atalhos de teclado)"
    log_output "  • Snippets personalizados"
    log_output "  • Perfis personalizados"
    log_output "  • Configuração de MCP Servers"
    log_output "  • Workspace storage (histórico e estado)"
    log_output "  • Metadados do backup (data, versão, etc.)"
    log_output ""
    log_output "${LIGHT_GREEN}Nota:${NC}"
    log_output "  Extensões não são incluídas no backup. Use o gerenciador interno"
    log_output "  do Cursor para sincronizar extensões."
}

# Create backup of Cursor configurations
create_backup() {
    local backup_name="${1:-}"

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

    # Check if configuration directory exists
    if [ ! -d "$CURSOR_CONFIG_DIR" ]; then
        log_error "Diretório de configuração do Cursor não encontrado: $CURSOR_CONFIG_DIR"
        log_info "Certifique-se de ter executado o Cursor pelo menos uma vez"
        return 1
    fi

    # Generate backup name if not provided
    if [ -z "$backup_name" ]; then
        backup_name="cursor-backup-$(date +%Y%m%d-%H%M%S)"
    fi

    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"

    local backup_path="$BACKUP_DIR/$backup_name"
    local backup_archive="$backup_path.tar.gz"

    log_info "Criando backup do Cursor..."
    log_debug "Backup será salvo em: $backup_archive"

    # Create temporary directory for backup
    local temp_backup_dir=$(mktemp -d)
    local backup_content_dir="$temp_backup_dir/cursor-backup"
    mkdir -p "$backup_content_dir"

    # Backup User settings
    if [ -d "$CURSOR_CONFIG_DIR/User" ]; then
        log_info "Copiando configurações do usuário..."
        mkdir -p "$backup_content_dir/User"

        # Copy settings.json
        if [ -f "$CURSOR_CONFIG_DIR/User/settings.json" ]; then
            log_debug "Copiando settings.json..."
            cp "$CURSOR_CONFIG_DIR/User/settings.json" "$backup_content_dir/User/" 2> /dev/null || true
        fi

        # Copy keybindings
        if [ -f "$CURSOR_CONFIG_DIR/User/keybindings.json" ]; then
            log_debug "Copiando keybindings.json..."
            cp "$CURSOR_CONFIG_DIR/User/keybindings.json" "$backup_content_dir/User/" 2> /dev/null || true
        fi
    fi

    # Backup User profiles
    if [ -d "$CURSOR_CONFIG_DIR/User/profiles" ]; then
        log_info "Copiando perfis de usuário..."
        mkdir -p "$backup_content_dir/User/profiles"
        cp -r "$CURSOR_CONFIG_DIR/User/profiles"/* "$backup_content_dir/User/profiles/" 2> /dev/null || true
    fi

    # Backup snippets
    if [ -d "$CURSOR_CONFIG_DIR/User/snippets" ]; then
        log_info "Copiando snippets..."
        mkdir -p "$backup_content_dir/User/snippets"
        cp -r "$CURSOR_CONFIG_DIR/User/snippets"/* "$backup_content_dir/User/snippets/" 2> /dev/null || true
    fi

    # Backup MCP servers configuration (specific to Cursor)
    # MCP servers config is typically in User/globalStorage
    local mcp_config_dir="$CURSOR_CONFIG_DIR/User/globalStorage"
    if [ -d "$mcp_config_dir" ]; then
        log_info "Copiando configuração de MCP Servers..."
        mkdir -p "$backup_content_dir/User/globalStorage"

        # Look for MCP-related configurations
        # Cursor stores MCP config in different possible locations
        local mcp_patterns=(
            "*/mcp*.json"
            "*/modelcontextprotocol*.json"
            "*cursor*/mcp*"
        )

        local found_mcp=false
        for pattern in "${mcp_patterns[@]}"; do
            if ls "$mcp_config_dir"/$pattern 1> /dev/null 2>&1; then
                cp -r "$mcp_config_dir"/$pattern "$backup_content_dir/User/globalStorage/" 2> /dev/null || true
                found_mcp=true
            fi
        done

        # Also backup the entire globalStorage if it contains cursor-specific data
        if [ -d "$mcp_config_dir/anysphere.cursor" ]; then
            log_debug "Copiando globalStorage do Cursor..."
            cp -r "$mcp_config_dir/anysphere.cursor" "$backup_content_dir/User/globalStorage/" 2> /dev/null || true
        fi

        if $found_mcp; then
            log_debug "Configurações MCP encontradas e copiadas"
        fi
    fi

    # Backup workspace storage (history, recent files, etc)
    if [ -d "$CURSOR_CONFIG_DIR/User/workspaceStorage" ]; then
        log_info "Copiando workspace storage..."
        mkdir -p "$backup_content_dir/User/workspaceStorage"

        # Only backup metadata, not the full cache (can be large)
        find "$CURSOR_CONFIG_DIR/User/workspaceStorage" -name "workspace.json" -o -name "state.vscdb" | while read -r file; do
            local rel_path="${file#"$CURSOR_CONFIG_DIR"/User/workspaceStorage/}"
            local target_dir="$backup_content_dir/User/workspaceStorage/$(dirname "$rel_path")"
            mkdir -p "$target_dir"
            cp "$file" "$target_dir/" 2> /dev/null || true
        done
    fi

    # Backup UI state and global state
    if [ -f "$CURSOR_CONFIG_DIR/User/globalStorage/state.vscdb" ]; then
        log_info "Copiando estado global..."
        mkdir -p "$backup_content_dir/User/globalStorage"
        cp "$CURSOR_CONFIG_DIR/User/globalStorage/state.vscdb" "$backup_content_dir/User/globalStorage/" 2> /dev/null || true
    fi

    # Create metadata file
    log_info "Criando arquivo de metadados..."
    local cursor_version=$(get_current_version)
    cat > "$backup_content_dir/backup-info.json" << EOF
{
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "os": "$(uname -s)",
  "cursor_version": "$cursor_version",
  "backup_name": "$backup_name",
  "config_dir": "$CURSOR_CONFIG_DIR",
  "includes": [
    "settings",
    "keybindings",
    "snippets",
    "profiles",
    "mcp_servers",
    "workspace_storage",
    "global_state"
  ]
}
EOF

    # Create compressed archive
    log_info "Compactando backup..."
    tar -czf "$backup_archive" -C "$temp_backup_dir" cursor-backup > /dev/null 2>&1

    # Clean up temporary directory
    rm -rf "$temp_backup_dir"

    if [ -f "$backup_archive" ]; then
        local backup_size=$(du -h "$backup_archive" | cut -f1)
        log_success "✓ Backup criado com sucesso!"
        log_output ""
        log_output "${LIGHT_GREEN}Local:${NC} $backup_archive"
        log_output "${LIGHT_GREEN}Tamanho:${NC} $backup_size"
        log_output ""
        log_output "${LIGHT_GREEN}Para restaurar:${NC}"
        log_output "  susa setup cursor backup restore $backup_name"
        return 0
    else
        log_error "Falha ao criar arquivo de backup"
        return 1
    fi
}

# Main function
main() {
    local backup_name=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name)
                backup_name="$2"
                shift 2
                ;;
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

    # Create backup
    create_backup "$backup_name"
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
