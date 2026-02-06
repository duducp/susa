#!/usr/bin/env zsh

UTILS_DIR="$(dirname "$0")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/shell.sh"
source "$UTILS_DIR/common.sh"

# Main function
main() {
    if check_installation; then
        log_info "Poetry $(get_current_version) já está instalado."
        log_output "Use ${LIGHT_CYAN}susa setup poetry update${NC} para atualizar"
        exit 0
    fi

    log_info "Iniciando instalação do Poetry..."

    local poetry_home="$POETRY_HOME"

    # Download and install Poetry using official installer
    log_info "Baixando instalador do Poetry..."

    local install_script="/tmp/poetry-installer-$$.py"

    if ! curl -sSL "$POETRY_INSTALL_URL" -o "$install_script"; then
        log_error "Falha ao baixar o instalador do Poetry"
        rm -f "$install_script"
        return 1
    fi

    log_debug "Instalador baixado em: $install_script"

    # Run installer
    log_info "Instalando Poetry..."
    log_debug "Executando instalador Python..."

    export POETRY_HOME="$poetry_home"

    if python3 "$install_script" 2>&1 | while read -r line; do log_debug "installer: $line"; done; then
        log_debug "Instalação concluída com sucesso"
    else
        log_error "Falha ao executar o instalador do Poetry"
        rm -f "$install_script"
        return 1
    fi

    rm -f "$install_script"
    log_debug "Instalador removido"

    # Configure shell
    configure_shell "$poetry_home"

    # Setup environment for current session
    setup_poetry_environment "$poetry_home"

    # Verify installation
    if check_installation; then
        local version=$(get_current_version)

        # Mark as installed in lock file
        register_or_update_software_in_lock "$COMMAND_NAME" "$version"

        log_success "Poetry $version instalado com sucesso!"

        echo ""
        echo "Próximos passos:"
        local shell_config=$(detect_shell_config)
        log_output "  1. Reinicie o terminal ou execute: ${LIGHT_CYAN}source $shell_config${NC}"
        log_output "  2. Crie um novo projeto: ${LIGHT_CYAN}poetry new meu-projeto${NC}"
        log_output "  3. Use ${LIGHT_CYAN}poetry --help${NC} para ver todos os comandos"

        return 0
    else
        log_error "Poetry foi instalado mas não está disponível no PATH"
        local shell_config=$(detect_shell_config)
        log_info "Tente reiniciar o terminal ou executar: source $shell_config"
        return 1
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
