#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/shell.sh"
source "$UTILS_DIR/common.sh"

# Show additional help
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  -y, --yes         Pula todas as confirmações"
    log_output ""
    log_output "${LIGHT_GREEN}Comportamento:${NC}"
    log_output "  • Remove o binário do Mise"
    log_output "  • Pergunta sobre remoção de ferramentas gerenciadas (Node, Python, etc)"
    log_output "  • Pergunta sobre remoção de configurações"
    log_output "  • Pergunta sobre remoção do cache"
    log_output "  • Remove configurações do shell (~/.bashrc ou ~/.zshrc)"
    log_output ""
    log_output "${LIGHT_GREEN}Modo automático (-y):${NC}"
    log_output "  Remove tudo automaticamente (binário, ferramentas, configs e cache)"
}

# Main function
main() {
    local skip_confirm=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y | --yes)
                skip_confirm=true
                shift
                ;;
            *)
                log_error "Opção desconhecida: $1"
                log_output ""
                log_output "Use ${LIGHT_CYAN}susa setup mise uninstall --help${NC} para ver opções disponíveis"
                exit 1
                ;;
        esac
    done

    local mise_bin="$LOCAL_BIN_DIR/$MISE_BIN_NAME"
    local shell_config=$(detect_shell_config)

    log_info "Desinstalando Mise..."

    # Check if Mise is installed
    if ! check_installation; then
        log_warning "Mise não está instalado"
        log_info "Nada a fazer"
        return 0
    fi

    local version=$(get_current_version)
    log_debug "Versão a ser removida: $version"

    # Confirm uninstallation
    if [ "$skip_confirm" = false ]; then
        echo ""
        log_output "${YELLOW}Deseja realmente desinstalar o Mise $version? (s/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    # Remove Mise binary
    if [ -f "$mise_bin" ]; then
        rm -f "$mise_bin"
        log_debug "Binário removido: $mise_bin"
    fi

    # Ask about removing managed tools (Node, Python, etc)
    if [ "$skip_confirm" = false ]; then
        echo ""
        log_output "${YELLOW}Deseja remover também as ferramentas gerenciadas pelo Mise (Node, Python, Go, etc)? (s/N)${NC}"
        read -r tools_response

        if [[ "$tools_response" =~ ^[sSyY]$ ]]; then
            if [ -d "$MISE_DATA_DIR" ]; then
                rm -rf "$MISE_DATA_DIR"
                log_debug "Ferramentas removidas: $MISE_DATA_DIR"
            fi
            log_success "Ferramentas gerenciadas removidas"
        else
            log_info "Ferramentas mantidas em $MISE_DATA_DIR"
        fi
    else
        # Auto-remove when --yes is used
        if [ -d "$MISE_DATA_DIR" ]; then
            rm -rf "$MISE_DATA_DIR"
            log_debug "Ferramentas removidas: $MISE_DATA_DIR"
        fi
        log_info "Ferramentas gerenciadas removidas automaticamente"
    fi

    # Remove Mise config directory
    if [ -d "$MISE_CONFIG_DIR" ]; then
        rm -rf "$MISE_CONFIG_DIR"
        log_debug "Configurações removidas: $MISE_CONFIG_DIR"
    fi

    # Remove shell configurations
    if [ -f "$shell_config" ] && is_mise_configured "$shell_config"; then
        local backup_file="${shell_config}.backup.$(date +%Y%m%d%H%M%S)"
        # Create backup
        cp "$shell_config" "$backup_file"
        # Remove Mise lines
        sed -i.tmp "/$MISE_CONFIG_COMMENT/d" "$shell_config"
        sed -i.tmp "/$MISE_ACTIVATE_PATTERN/d" "$shell_config"
        # Remove the line with PATH export that contains LOCAL_BIN_DIR
        sed -i.tmp "\|export PATH=\"$LOCAL_BIN_DIR:\$PATH\"|d" "$shell_config"
        rm -f "${shell_config}.tmp"
        log_debug "Configurações removidas (backup: $backup_file)"
    else
        log_debug "Nenhuma configuração encontrada em $shell_config"
    fi

    # Verify removal
    if ! check_installation; then
        log_success "Mise desinstalado com sucesso!"
        remove_software_in_lock "$COMMAND_NAME"
        echo ""
        log_info "Reinicie o terminal ou execute: ${LIGHT_CYAN}source $shell_config${NC}"
    else
        log_warning "Mise removido, mas executável ainda encontrado no PATH"
        log_debug "Pode ser necessário remover manualmente de: $(which $MISE_BIN_NAME)"
    fi

    # Ask about cache removal
    if [ "$skip_confirm" = false ]; then
        echo ""
        log_output "${YELLOW}Deseja remover também o cache do Mise? (s/N)${NC}"
        read -r cache_response

        if [[ "$cache_response" =~ ^[sSyY]$ ]]; then
            if [ -d "$MISE_CACHE_DIR" ]; then
                rm -rf "$MISE_CACHE_DIR" 2> /dev/null || true
                log_debug "Cache removido: $MISE_CACHE_DIR"
            fi
            log_success "Cache removido"
        else
            log_info "Cache mantido em $MISE_CACHE_DIR"
        fi
    else
        # Auto-remove cache when --yes is used
        if [ -d "$MISE_CACHE_DIR" ]; then
            rm -rf "$MISE_CACHE_DIR" 2> /dev/null || true
            log_debug "Cache removido: $MISE_CACHE_DIR"
        fi
        log_info "Cache removido automaticamente"
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
