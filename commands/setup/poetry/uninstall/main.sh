#!/usr/bin/env zsh

UTILS_DIR="$(dirname "$0")/../utils"

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
    log_output "  • Remove o Poetry do sistema"
    log_output "  • Pergunta sobre remoção de cache e configurações"
    log_output "  • Remove configurações do shell (~/.bashrc ou ~/.zshrc)"
    log_output ""
    log_output "${LIGHT_GREEN}Modo automático (-y):${NC}"
    log_output "  Remove tudo automaticamente (Poetry, cache e configurações)"
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
                log_output "Use ${LIGHT_CYAN}susa setup poetry uninstall --help${NC} para ver opções disponíveis"
                exit 1
                ;;
        esac
    done

    log_info "Desinstalando Poetry..."

    # Check if Poetry is installed
    if ! check_installation; then
        log_warning "Poetry não está instalado"
        log_info "Nada a fazer"
        return 0
    fi

    local version=$(get_current_version)
    log_debug "Versão a ser removida: $version"

    # Confirm uninstallation
    if [ "$skip_confirm" = false ]; then
        echo ""
        log_output "${YELLOW}Deseja realmente desinstalar o Poetry $version? (s/N)${NC}"
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    local poetry_home="$POETRY_HOME"

    # Download uninstaller
    log_info "Baixando desinstalador do Poetry..."

    local uninstall_script="/tmp/poetry-uninstaller-$$.py"

    if ! curl -sSL "$POETRY_INSTALL_URL" -o "$uninstall_script"; then
        log_error "Falha ao baixar o desinstalador"
        rm -f "$uninstall_script"

        # Fallback: remove manually
        log_info "Removendo manualmente..."
        rm -rf "$poetry_home"
    else
        log_debug "Desinstalador baixado em: $uninstall_script"

        # Run uninstaller
        log_info "Executando desinstalador..."

        export POETRY_HOME="$poetry_home"
        python3 "$uninstall_script" --uninstall 2>&1 | while read -r line; do log_debug "uninstaller: $line"; done || {
            log_debug "Desinstalador falhou, removendo manualmente..."
            rm -rf "$poetry_home"
        }

        rm -f "$uninstall_script"
        log_debug "Desinstalador removido"
    fi

    # Remove shell configurations
    remove_shell_config

    # Verify removal
    if ! check_installation; then
        # Mark as uninstalled in lock file
        remove_software_in_lock "$COMMAND_NAME"

        log_success "Poetry desinstalado com sucesso!"

        echo ""
        local shell_config=$(detect_shell_config)
        log_info "Reinicie o terminal ou execute: ${LIGHT_CYAN}source $shell_config${NC}"
    else
        log_warning "Poetry removido, mas executável ainda encontrado no PATH"
        local poetry_path=$(command -v poetry 2> /dev/null || echo "desconhecido")
        log_debug "Pode ser necessário remover manualmente de: $poetry_path"
    fi

    # Ask about cache and config removal
    if [ "$skip_confirm" = false ]; then
        echo ""
        log_output "${YELLOW}Deseja remover também o cache e configurações do Poetry? (s/N)${NC}"
        read -r config_response

        if [[ "$config_response" =~ ^[sSyY]$ ]]; then
            remove_poetry_data
        else
            log_info "Cache e configurações mantidos"
        fi
    else
        # Auto-remove cache and config when --yes is used
        remove_poetry_data
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
