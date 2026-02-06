#!/usr/bin/env zsh

UTILS_DIR="$(dirname "$0")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/flatpak.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"
source "$UTILS_DIR/install.sh"

# Show additional info in commando help
show_complement_help() {
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  $DBEAVER_NAME é uma ferramenta universal de gerenciamento de banco de dados,"
    log_output "  gratuita e open-source. Suporta MySQL, PostgreSQL, SQLite, Oracle,"
    log_output "  SQL Server, DB2, Sybase, MS Access, Teradata, Firebird, Apache Hive,"
    log_output "  Phoenix, Presto e mais de 80 tipos de bancos de dados."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup dbeaver install              # Instala o $DBEAVER_NAME"
    log_output "  susa setup dbeaver install -v           # Instala com saída detalhada"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  O DBeaver estará disponível no menu de aplicativos ou via:"
    log_output "    flatpak run $FLATPAK_APP_ID    (Linux)"
    log_output "    open -a DBeaver                (macOS)"
    log_output "    dbeaver                        (macOS)"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Suporte a 80+ tipos de bancos de dados"
    log_output "  • Editor SQL com syntax highlighting e autocompletar"
    log_output "  • Navegador de schema e metadata"
    log_output "  • Editor ER Diagram"
    log_output "  • Transferência de dados entre databases"
    log_output "  • Execução de scripts e queries"
    log_output "  • Geração de dados mock"
}

# Main installation function
install_dbeaver() {
    if check_installation; then
        log_info "DBeaver $(get_current_version) já está instalado."
        exit 0
    fi

    log_info "Iniciando instalação do DBeaver..."

    # Detect OS and install
    if is_mac; then
        install_dbeaver_macos
    else
        install_dbeaver_linux
    fi

    local install_result=$?

    if [ $install_result -eq 0 ]; then
        if check_installation; then
            local installed_version=$(get_current_version)
            register_or_update_software_in_lock "$COMMAND_NAME" "$installed_version"

            log_success "DBeaver $installed_version instalado com sucesso!"
            log_output ""
            log_output "Próximos passos:"
            log_output "  1. Abra o DBeaver pelo menu de aplicativos"
            log_output "  2. Configure suas conexões de banco de dados"
            log_output "  3. Use ${LIGHT_CYAN}susa setup dbeaver --help${NC} para mais comandos disponíveis"
        else
            log_error "Instalação concluída mas DBeaver não foi encontrado"
            return 1
        fi
    else
        log_error "Falha na instalação do DBeaver"
        return 1
    fi
}

# Main execution
main() {
    install_dbeaver
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
