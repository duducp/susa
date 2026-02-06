#!/usr/bin/env zsh

UTILS_DIR="$(dirname "$0")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/homebrew.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/shell.sh"
source "$UTILS_DIR/common.sh"

# Show additional help
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  -y, --yes         Pula todas as confirmações"
    log_output ""
    log_output "${LIGHT_GREEN}Comportamento:${NC}"
    log_output "  • Remove o binário do Podman"
    log_output "  • Remove podman-compose"
    log_output "  • Pergunta sobre remoção de imagens, containers e volumes"
    log_output "  • No macOS: Para e remove a máquina virtual do Podman"
    log_output ""
    log_output "${LIGHT_GREEN}Modo automático (-y):${NC}"
    log_output "  Remove tudo automaticamente (binário, compose, dados e cache)"
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
                log_output "Use ${LIGHT_CYAN}susa setup podman uninstall --help${NC} para ver opções disponíveis"
                exit 1
                ;;
        esac
    done

    log_info "Desinstalando Podman..."

    # Check if Podman is installed
    if ! check_installation; then
        log_warning "Podman não está instalado"
        log_info "Nada a fazer"
        return 0
    fi

    local version=$(get_current_version)
    log_debug "Versão a ser removida: $version"

    # Confirm uninstallation
    if [ "$skip_confirm" = false ]; then
        echo ""
        log_output "${YELLOW}Deseja realmente desinstalar o Podman $version? (s/N)${NC}"
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    local shell_config=$(detect_shell_config)

    # Uninstall based on OS
    if is_mac; then
        uninstall_podman_macos
    else
        uninstall_podman_linux
    fi

    # Verify removal
    if ! check_installation; then
        log_success "Podman desinstalado com sucesso!"
        remove_software_in_lock "$COMMAND_NAME"

        echo ""
        log_info "Reinicie o terminal ou execute: ${LIGHT_CYAN}source $shell_config${NC}"
    else
        log_warning "Podman removido, mas executável ainda encontrado no PATH"
        log_debug "Pode ser necessário remover manualmente de: $(which $PODMAN_BIN_NAME)"
    fi

    # Ask about removing Podman data (images, containers, volumes)
    if [ "$skip_confirm" = false ]; then
        echo ""
        log_output "${YELLOW}Deseja remover também as imagens, containers e volumes do Podman? (s/N)${NC}"
        read -r data_response

        if [[ "$data_response" =~ ^[sSyY]$ ]]; then
            remove_podman_data
        else
            log_info "Dados do Podman mantidos"
        fi
    else
        # Auto-remove when --yes is used
        remove_podman_data
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
