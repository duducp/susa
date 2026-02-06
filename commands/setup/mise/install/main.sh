#!/usr/bin/env zsh

UTILS_DIR="$(dirname "$0")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/shell.sh"
source "$UTILS_DIR/common.sh"

# Show additional help
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  -y, --yes         Pula confirmação de suporte a arquivos legados"
    log_output ""
    log_output "${LIGHT_GREEN}Suporte ao Legado:${NC}"
    log_output "  Durante a instalação, você pode habilitar suporte a arquivos legados"
    log_output "  de outros gerenciadores (.tool-versions, .python-version, .node-version, .nvmrc, .go-version)."
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Após a instalação, reinicie o terminal ou execute:"
    log_output "    ${LIGHT_CYAN}source ~/.bashrc${NC}   (para Bash)"
    log_output "    ${LIGHT_CYAN}source ~/.zshrc${NC}    (para Zsh)"
}

# Main installation function
install_mise_release() {
    local bin_dir="$LOCAL_BIN_DIR"
    local mise_version=$(get_latest_version)

    if [ $? -ne 0 ] || [ -z "$mise_version" ]; then
        return 1
    fi

    # Detect OS and architecture
    local os_arch=$(github_detect_os_arch "standard")
    [ $? -ne 0 ] && return 1

    local os_name="${os_arch%:*}"
    local arch="${os_arch#*:}"

    log_info "Instalando Mise $mise_version..."

    # Download release
    local tar_file=$(download_mise "$mise_version" "$os_name" "$arch")
    if [ $? -ne 0 ] || [ -z "$tar_file" ]; then
        log_error "Não foi possível baixar o Mise. Tente novamente mais tarde."
        return 1
    fi

    # Extract and setup binary
    extract_and_setup_binary "$tar_file" "$bin_dir"
    [ $? -ne 0 ] && return 1

    # Configure shell
    configure_shell

    # Setup environment for current session
    setup_mise_environment "$bin_dir"
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
                log_output "Use ${LIGHT_CYAN}susa setup mise install --help${NC} para ver opções disponíveis"
                exit 1
                ;;
        esac
    done

    # Check if already installed
    if check_installation; then
        log_info "Mise $(get_current_version) já está instalado."
        log_output "Use ${LIGHT_CYAN}susa setup mise update${NC} para atualizar"
        exit 0
    fi

    log_info "Iniciando instalação do Mise..."

    # Ask about legacy version file support
    local enable_legacy="false"
    if [ "$skip_confirm" = false ]; then
        echo ""
        log_output "${YELLOW}Deseja habilitar suporte a arquivos legados?${NC}"
        log_output "${DIM}(Permite ler .tool-versions, .node-version, .python-version, etc)${NC}"
        log_output "${YELLOW}Recomendado se você já trabalha com projetos existentes (S/n)${NC}"
        read -r legacy_response

        # Default to yes if empty or starts with s/S/y/Y
        if [[ -z "$legacy_response" ]] || [[ "$legacy_response" =~ ^[sSyY] ]]; then
            enable_legacy="true"
        fi
    else
        # In auto mode, enable legacy support by default
        enable_legacy="true"
        log_info "Suporte ao legado habilitado automaticamente (modo --yes)"
    fi

    # Install Mise
    install_mise_release
    configure_legacy_support "$enable_legacy"

    # Verify installation
    local shell_config=$(detect_shell_config)
    if check_installation; then
        local version=$(get_current_version)
        log_success "Mise $version instalado com sucesso!"
        register_or_update_software_in_lock "$COMMAND_NAME" "$version"
        echo ""
        echo "Próximos passos:"
        log_output "  1. Reinicie o terminal ou execute: ${LIGHT_CYAN}source $shell_config${NC}"
        log_output "  2. Instale ferramentas: ${LIGHT_CYAN}mise use --global node@20${NC}"
        log_output "  3. Use ${LIGHT_CYAN}mise --help${NC} para ver todos os comandos"
    else
        log_error "Mise foi instalado mas não está disponível no PATH"
        log_info "Tente reiniciar o terminal ou executar: source $shell_config"
        return 1
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
