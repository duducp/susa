#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# Restore DBeaver configurations from backup
# Source libraries
UTILS_DIR="$(dirname "$0")/../../utils"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/flatpak.sh"
source "$LIB_DIR/snap.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

# Default backup directory
DEFAULT_BACKUP_DIR="$HOME/.susa/backups/dbeaver"
BACKUP_DIR="${DBEAVER_BACKUP_DIR:-$DEFAULT_BACKUP_DIR}"

# Show help
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  -y, --yes               Pula confirmação"
    log_output "  --info                  Mostra informações do backup sem restaurar"
    log_output "  --dir <diretório>       Diretório de onde restaurar o backup"
    log_output ""
    log_output "${LIGHT_GREEN}Argumentos:${NC}"
    log_output "  <nome-do-backup>        Nome do backup a ser restaurado"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup dbeaver backup restore my-backup        # Restaura backup específico"
    log_output "  susa setup dbeaver backup restore my-backup -y     # Restaura sem confirmação"
    log_output "  susa setup dbeaver backup restore my-backup --info # Mostra info do backup"
    log_output ""
    log_output "${LIGHT_GREEN}Nota:${NC}"
    log_output "  Um backup de segurança das configurações atuais é criado automaticamente"
    log_output "  antes da restauração, permitindo reverter se necessário."
    log_output "  O restore sobrescreve completamente o workspace6 existente."
}

# Find backup file
find_backup_file() {
    local backup_name="$1"
    local backup_archive=""

    # First, try the default backup directory
    if [ -f "$BACKUP_DIR/$backup_name.tar.gz" ]; then
        backup_archive="$BACKUP_DIR/$backup_name.tar.gz"
    # Then, try the current directory
    elif [ -f "$PWD/$backup_name.tar.gz" ]; then
        backup_archive="$PWD/$backup_name.tar.gz"
    # Also try without .tar.gz extension in both locations
    elif [ -f "$BACKUP_DIR/$backup_name" ]; then
        backup_archive="$BACKUP_DIR/$backup_name"
    elif [ -f "$PWD/$backup_name" ]; then
        backup_archive="$PWD/$backup_name"
    fi

    echo "$backup_archive"
}

# Show backup information
show_backup_info() {
    local backup_name="$1"
    local backup_archive=$(find_backup_file "$backup_name")

    if [ -z "$backup_archive" ] || [ ! -f "$backup_archive" ]; then
        log_error "Backup não encontrado: $backup_name"
        log_info "Locais verificados:"
        log_info "  - $BACKUP_DIR/$backup_name.tar.gz"
        log_info "  - $PWD/$backup_name.tar.gz"
        log_info "Use: susa setup dbeaver backup list"
        return 1
    fi

    # Create temporary directory to extract metadata
    local temp_dir=$(mktemp -d)

    log_info "Extraindo informações do backup..."
    tar -xzf "$backup_archive" -C "$temp_dir" dbeaver-backup/backup-info.json 2> /dev/null || {
        log_error "Falha ao extrair informações do backup"
        rm -rf "$temp_dir"
        return 1
    }

    log_output ""
    log_output "${LIGHT_GREEN}Informações do Backup:${NC}"
    log_output "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if command -v jq &> /dev/null; then
        local info_file="$temp_dir/dbeaver-backup/backup-info.json"

        local created_at=$(jq -r '.created_at' "$info_file")
        local os=$(jq -r '.os' "$info_file")
        local dbeaver_version=$(jq -r '.dbeaver_version' "$info_file")
        local backup_name_info=$(jq -r '.backup_name' "$info_file")
        local include_scripts=$(jq -r '.include_scripts' "$info_file")
        local include_connections=$(jq -r '.include_connections' "$info_file")

        log_output "${LIGHT_CYAN}Nome:${NC} $backup_name_info"
        log_output "${LIGHT_CYAN}Criado em:${NC} $created_at"
        log_output "${LIGHT_CYAN}Sistema:${NC} $os"
        log_output "${LIGHT_CYAN}Versão DBeaver:${NC} $dbeaver_version"
        log_output "${LIGHT_CYAN}Scripts incluídos:${NC} $include_scripts"
        log_output "${LIGHT_CYAN}Conexões incluídas:${NC} $include_connections"
    else
        log_warning "jq não instalado, mostrando informações básicas"
        cat "$temp_dir/dbeaver-backup/backup-info.json"
    fi

    local backup_size=$(du -h "$backup_archive" | cut -f1)
    log_output "${LIGHT_CYAN}Tamanho:${NC} $backup_size"
    log_output "${LIGHT_CYAN}Local:${NC} $backup_archive"
    log_output ""

    # Clean up
    rm -rf "$temp_dir"

    return 0
}

# Create safety backup
create_safety_backup() {
    # Use backup mode to read current configurations
    if ! get_dbeaver_config_paths "backup"; then
        return 1
    fi

    if [ ! -d "$DBEAVER_CONFIG_DIR" ]; then
        log_debug "Nenhuma configuração existente encontrada, pulando backup de segurança"
        return 0
    fi

    local safety_backup_name="dbeaver-safety-backup-$(date +%Y%m%d-%H%M%S)"
    local safety_backup_archive="$BACKUP_DIR/$safety_backup_name.tar.gz"

    log_info "Criando backup de segurança das configurações atuais..."

    mkdir -p "$BACKUP_DIR"

    local temp_backup_dir=$(mktemp -d)
    cp -r "$DBEAVER_CONFIG_DIR" "$temp_backup_dir/dbeaver-backup" 2> /dev/null || true

    tar -czf "$safety_backup_archive" -C "$temp_backup_dir" dbeaver-backup > /dev/null 2>&1
    rm -rf "$temp_backup_dir"

    if [ -f "$safety_backup_archive" ]; then
        log_success "✓ Backup de segurança criado: $safety_backup_name"
        return 0
    else
        log_warning "⚠ Falha ao criar backup de segurança"
        return 1
    fi
}

# Restore backup
restore_backup() {
    local backup_name="$1"
    local skip_confirm="${2:-false}"

    # Check if DBeaver is installed
    if ! check_installation; then
        log_error "DBeaver não está instalado"
        log_info "Use: susa setup dbeaver install"
        return 1
    fi

    # Get configuration paths (modo restore: always use common/ for Snap)
    if ! get_dbeaver_config_paths "restore"; then
        return 1
    fi

    # Find backup file
    local backup_archive=$(find_backup_file "$backup_name")

    if [ -z "$backup_archive" ] || [ ! -f "$backup_archive" ]; then
        log_error "Backup não encontrado: $backup_name"
        log_info "Use: susa setup dbeaver backup list"
        return 1
    fi

    log_info "Backup encontrado: $backup_archive"

    # Show confirmation
    if [ "$skip_confirm" != "true" ]; then
        log_output ""
        log_output "${YELLOW}⚠  ATENÇÃO: Esta operação irá substituir suas configurações atuais do DBeaver!${NC}"
        log_output ""
        log_output "Deseja continuar? (s/N) "
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Restauração cancelada"
            return 0
        fi
    fi

    # Create safety backup
    create_safety_backup

    # Create temporary directory for extraction
    local temp_dir=$(mktemp -d)

    log_info "Extraindo backup..."
    tar -xzf "$backup_archive" -C "$temp_dir" > /dev/null 2>&1 || {
        log_error "Falha ao extrair backup"
        rm -rf "$temp_dir"
        return 1
    }

    # Check if workspace6 exists in backup
    if [ ! -d "$temp_dir/dbeaver-backup/workspace6" ]; then
        log_error "Backup não contém pasta workspace6"
        rm -rf "$temp_dir"
        return 1
    fi

    # Get parent directory of DBEAVER_CONFIG_DIR to restore workspace6
    local parent_dir=$(dirname "$DBEAVER_CONFIG_DIR")

    log_info "Restaurando workspace completo do DBeaver..."
    log_debug "Destino: $DBEAVER_CONFIG_DIR"

    # Remove existing workspace6 directory
    if [ -d "$DBEAVER_CONFIG_DIR" ]; then
        log_debug "Removendo workspace6 existente"
        rm -rf "$DBEAVER_CONFIG_DIR"
    fi

    # Ensure parent directory exists
    mkdir -p "$parent_dir"

    # Restore entire workspace6 directory
    cp -r "$temp_dir/dbeaver-backup/workspace6" "$DBEAVER_CONFIG_DIR" 2> /dev/null || {
        log_error "Falha ao restaurar workspace completo"
        rm -rf "$temp_dir"
        return 1
    }

    # Clean up
    rm -rf "$temp_dir"

    log_success "✓ Backup restaurado com sucesso!"
    log_output ""
    log_output "${LIGHT_GREEN}Próximos passos:${NC}"
    log_output "  1. Reinicie o DBeaver para aplicar as configurações"
    log_output "  2. Verifique suas conexões e atualize senhas se necessário"
    log_output ""

    return 0
}

# Main function
main() {
    local backup_name=""
    local skip_confirm="false"
    local show_info="false"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y | --yes)
                skip_confirm="true"
                shift
                ;;
            --info)
                show_info="true"
                shift
                ;;
            --dir)
                BACKUP_DIR="$2"
                shift 2
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

    # Validate backup name
    if [ -z "$backup_name" ]; then
        log_error "Nome do backup não especificado"
        show_usage "<nome-do-backup> [opções]"
        log_output ""
        log_info "Use: susa setup dbeaver backup list para ver backups disponíveis"
        exit 1
    fi

    # Show info or restore
    if [ "$show_info" = "true" ]; then
        show_backup_info "$backup_name"
    else
        restore_backup "$backup_name" "$skip_confirm"
    fi
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
