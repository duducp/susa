#!/usr/bin/env zsh

UTILS_DIR="$(dirname "$0")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/snap.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"
source "$UTILS_DIR/install.sh"

# Show additional info in command help
show_complement_help() {
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  $NORDPASS_NAME é um gerenciador de senhas seguro e intuitivo."
    log_output "  Oferece armazenamento criptografado de senhas, cartões de crédito"
    log_output "  e notas seguras, com sincronização entre dispositivos."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup nordpass install              # Instala o $NORDPASS_NAME"
    log_output "  susa setup nordpass install -v           # Instala com saída detalhada"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  O NordPass estará disponível no menu de aplicativos ou via:"
    log_output "    snap run $SNAP_APP_NAME    (Linux)"
    log_output "    open '/Applications/NordPass.app'    (macOS)"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Armazenamento criptografado de senhas"
    log_output "  • Gerador de senhas fortes"
    log_output "  • Sincronização multi-dispositivo"
    log_output "  • Autopreenchimento de formulários"
    log_output "  • Autenticação de dois fatores"
    log_output "  • Verificação de vazamento de dados"
}

# Main installation function
install_nordpass() {
    if check_installation; then
        log_info "NordPass $(get_current_version) já está instalado."
        exit 0
    fi

    log_info "Iniciando instalação do NordPass..."

    # Detect OS and install
    if is_mac; then
        install_nordpass_macos
    else
        install_nordpass_linux
    fi

    local install_result=$?

    if [ $install_result -eq 0 ]; then
        if check_installation; then
            local installed_version=$(get_current_version)
            register_or_update_software_in_lock "$COMMAND_NAME" "$installed_version"

            log_success "NordPass $installed_version instalado com sucesso!"
            log_output ""
            log_output "Próximos passos:"
            log_output "  1. Abra o NordPass pelo menu de aplicativos"
            log_output "  2. Crie ou faça login na sua conta NordPass"
            log_output "  3. Use ${LIGHT_CYAN}susa setup nordpass --help${NC} para mais comandos disponíveis"
        else
            log_error "Instalação concluída mas NordPass não foi encontrado"
            return 1
        fi
    else
        log_error "Falha na instalação do NordPass"
        return 1
    fi
}

# Main execution
main() {
    install_nordpass
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
