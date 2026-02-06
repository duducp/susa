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
    log_output "  PostgreSQL Client é o conjunto de ferramentas de linha de comando"
    log_output "  para interagir com servidores PostgreSQL. Inclui psql (cliente"
    log_output "  interativo), pg_dump, pg_restore e outros utilitários."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup postgres install              # Instala o PostgreSQL Client"
    log_output "  susa setup postgres install -v           # Instala com saída detalhada"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Conectar a um servidor PostgreSQL:"
    log_output "    psql -h hostname -U username -d database"
    log_output ""
    log_output "${LIGHT_GREEN}Utilitários incluídos:${NC}"
    log_output "  psql          Cliente interativo"
    log_output "  pg_dump       Backup de banco de dados"
    log_output "  pg_restore    Restauração de backup"
    log_output "  createdb      Criar banco de dados"
    log_output "  dropdb        Remover banco de dados"
    log_output "  pg_isready    Verificar status do servidor"
}

# Main execution
main() {
    if check_installation; then
        log_info "PostgreSQL Client $(get_current_version) já está instalado."
        log_info "Use 'susa setup postgres update' para atualizar."
        exit 0
    fi

    log_info "Iniciando instalação do PostgreSQL Client..."

    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local install_result=1

    case "$os_name" in
        darwin)
            install_postgres_macos
            install_result=$?
            ;;
        linux)
            local distro="$(get_distro_id)"
            log_debug "Distribuição detectada: $distro"

            case "$distro" in
                ubuntu | debian | pop | linuxmint)
                    install_postgres_debian
                    install_result=$?
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    install_postgres_redhat
                    install_result=$?
                    ;;
                arch | manjaro)
                    install_postgres_arch
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
            log_success "PostgreSQL Client $installed_version instalado com sucesso!"
            register_or_update_software_in_lock "postgres" "$installed_version"

            echo ""
            log_output "Próximos passos:"
            log_output "  1. Teste a instalação: ${LIGHT_CYAN}psql --version${NC}"
            log_output "  2. Conecte a um servidor: ${LIGHT_CYAN}psql -h hostname -U username -d database${NC}"
            log_output "  3. Use ${LIGHT_CYAN}susa setup postgres --help${NC} para mais comandos disponíveis"
        else
            log_error "PostgreSQL Client foi instalado mas não está disponível no PATH"
            if [ "$os_name" = "darwin" ]; then
                log_output ""
                log_output "No macOS, você pode precisar adicionar ao PATH:"
                log_output "  export PATH=\"$POSTGRES_HOMEBREW_PATH:\$PATH\""
                log_output ""
                log_output "Adicione esta linha ao seu ~/.zshrc ou ~/.bashrc"
            fi
            return 1
        fi
    else
        log_error "Falha na instalação do PostgreSQL Client"
        return $install_result
    fi
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
