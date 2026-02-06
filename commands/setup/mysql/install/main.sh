#!/usr/bin/env zsh

UTILS_DIR="$(dirname "$0")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$UTILS_DIR/common.sh"
source "$UTILS_DIR/install.sh"

# Show additional info in command help
show_complement_help() {
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  MySQL Client é o utilitário de linha de comando para interagir com servidores MySQL."
    log_output "  Inclui os comandos mysql, mysqldump, mysqladmin e outros utilitários essenciais."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup mysql install              # Instala o MySQL Client"
    log_output "  susa setup mysql install -v           # Instala com saída detalhada"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Conectar a um servidor MySQL:"
    log_output "    mysql -h hostname -u username -p database"
    log_output ""
    log_output "${LIGHT_GREEN}Utilitários incluídos:${NC}"
    log_output "  mysql         Cliente interativo"
    log_output "  mysqldump     Backup de banco de dados"
    log_output "  mysqladmin    Administração do servidor"
    log_output "  mysqlimport   Importação de dados"
}

# Main installation function
install_mysql() {
    if check_installation; then
        log_info "MySQL Client $(get_current_version) já está instalado."
        log_info "Use 'susa setup mysql update' para atualizar."
        exit 0
    fi

    log_info "Iniciando instalação do MySQL Client..."

    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local install_result=1

    case "$os_name" in
        darwin)
            install_mysql_macos
            install_result=$?
            ;;
        linux)
            local distro="$(get_distro_id)"
            log_debug "Distribuição detectada: $distro"

            case "$distro" in
                ubuntu | debian | pop | linuxmint)
                    install_mysql_debian
                    install_result=$?
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    install_mysql_redhat
                    install_result=$?
                    ;;
                arch | manjaro)
                    install_mysql_arch
                    install_result=$?
                    ;;
                *)
                    log_error "Distribuição Linux não suportada: $distro"
                    log_output "Instale manualmente usando o gerenciador de pacotes da sua distribuição"
                    return 1
                    ;;
            esac
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    if [ $install_result -eq 0 ]; then
        if check_installation; then
            local installed_version=$(get_current_version)
            log_success "MySQL Client $installed_version instalado com sucesso!"
            register_or_update_software_in_lock "mysql" "$installed_version"

            echo ""
            log_output "Próximos passos:"
            log_output "  1. Teste a instalação: ${LIGHT_CYAN}mysql --version${NC}"
            log_output "  2. Conecte a um servidor: ${LIGHT_CYAN}mysql -h hostname -u username -p database${NC}"
            log_output "  3. Use ${LIGHT_CYAN}susa setup mysql --help${NC} para mais comandos disponíveis"
        else
            log_error "MySQL Client foi instalado mas não está disponível no PATH"
            if [ "$os_name" = "darwin" ]; then
                log_output ""
                log_output "No macOS, você pode precisar adicionar ao PATH:"
                log_output "  export PATH=\"$MYSQL_HOMEBREW_PATH:\$PATH\""
                log_output ""
                log_output "Adicione esta linha ao seu ~/.zshrc ou ~/.bashrc"
            fi
            return 1
        fi
    else
        log_error "Falha na instalação do MySQL Client"
        return $install_result
    fi
}

# Main execution
main() {
    install_mysql
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
