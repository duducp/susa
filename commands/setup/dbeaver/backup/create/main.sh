#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Create backup of DBeaver configurations and scripts
# Source libraries
UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../../utils"
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
    log_output "  --name <nome>           Nome do backup (padrão: dbeaver-backup-YYYYMMDD-HHMMSS)"
    log_output "  --dir <diretório>       Diretório onde salvar o backup"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup dbeaver backup create                       # Cria backup com nome automático"
    log_output "  susa setup dbeaver backup create --name my-backup      # Cria backup com nome específico"
    log_output "  susa setup dbeaver backup create --dir /caminho        # Salva em diretório específico"
    log_output ""
    log_output "${LIGHT_GREEN}O que é incluído no backup:${NC}"
    log_output "  • Workspace completo (pasta workspace6)"
    log_output "  • Todas as configurações e preferências"
    log_output "  • Scripts SQL salvos"
    log_output "  • Configurações de conexões"
    log_output "  • Drivers personalizados"
    log_output "  • Metadados e histórico"
    log_output ""
    log_output "${LIGHT_GREEN}Nota:${NC}"
    log_output "  Senhas de conexões não são incluídas no backup por questões de segurança."
}

# Create backup of DBeaver configurations
create_backup() {
    local backup_name="${1:-}"

    # Check if DBeaver is installed (via Flatpak, Homebrew, or alternative methods)
    if ! check_installation; then
        log_error "DBeaver não está instalado"
        log_info "Use: susa setup dbeaver install"
        return 1
    fi

    # Log installation method for debugging
    if is_mac; then
        if homebrew_is_installed "$DBEAVER_HOMEBREW_CASK"; then
            log_debug "DBeaver instalado via Homebrew"
        fi
    else
        if flatpak_is_installed "$FLATPAK_APP_ID"; then
            log_debug "DBeaver instalado via Flatpak"
        elif snap_is_installed "$SNAP_PACKAGE_NAME"; then
            log_debug "DBeaver instalado via Snap"
        elif check_installation_alternative; then
            log_debug "DBeaver instalado manualmente ou via gerenciador de pacotes"
        fi
    fi

    # Get configuration paths (modo backup: lê de onde os dados estão)
    if ! get_dbeaver_config_paths "backup"; then
        return 1
    fi

    # Check if configuration directory exists
    if [ ! -d "$DBEAVER_CONFIG_DIR" ]; then
        log_error "Diretório de configuração do DBeaver não encontrado: $DBEAVER_CONFIG_DIR"
        log_info "Certifique-se de ter executado o DBeaver pelo menos uma vez"
        return 1
    fi

    # Generate backup name if not provided
    if [ -z "$backup_name" ]; then
        backup_name="dbeaver-backup-$(date +%Y%m%d-%H%M%S)"
    fi

    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"

    local backup_path="$BACKUP_DIR/$backup_name"
    local backup_archive="$backup_path.tar.gz"

    log_info "Criando backup do DBeaver..."
    log_debug "Backup será salvo em: $backup_archive"

    # Create temporary directory for backup
    local temp_backup_dir=$(mktemp -d)
    local backup_content_dir="$temp_backup_dir/dbeaver-backup"
    mkdir -p "$backup_content_dir"

    # Backup entire workspace6 directory
    log_info "Copiando workspace completo do DBeaver..."
    log_debug "Origem: $DBEAVER_CONFIG_DIR"
    log_debug "Destino: $backup_content_dir/workspace6"

    cp -r "$DBEAVER_CONFIG_DIR" "$backup_content_dir/workspace6" 2> /dev/null || {
        log_error "Falha ao copiar workspace completo"
        rm -rf "$temp_backup_dir"
        return 1
    }

    # Create metadata file
    log_info "Criando arquivo de metadados..."
    local dbeaver_version="desconhecida"
    if command -v dbeaver &> /dev/null; then
        dbeaver_version=$(dbeaver --version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida")
    fi

    cat > "$backup_content_dir/backup-info.json" << EOF
{
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "os": "$(uname -s)",
  "dbeaver_version": "$dbeaver_version",
  "backup_name": "$backup_name",
  "backup_type": "full_workspace"
}
EOF

    # Create compressed archive
    log_info "Compactando backup..."
    tar -czf "$backup_archive" -C "$temp_backup_dir" dbeaver-backup > /dev/null 2>&1

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
        log_output "  susa setup dbeaver backup restore $backup_name"
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
