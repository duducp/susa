#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/os.sh"
source "$UTILS_DIR/common.sh"
source "$UTILS_DIR/install.sh"

# Show additional info in command help
show_complement_help() {
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Redis CLI é o cliente de linha de comando para interagir com"
    log_output "  servidores Redis. Inclui redis-cli (cliente interativo) e"
    log_output "  redis-benchmark (ferramenta de teste de performance)."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup redis install              # Instala o Redis CLI"
    log_output "  susa setup redis install -v           # Instala com saída detalhada"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Conectar a um servidor Redis:"
    log_output "    redis-cli -h hostname -p port"
    log_output ""
    log_output "${LIGHT_GREEN}Utilitários incluídos:${NC}"
    log_output "  redis-cli         Cliente interativo"
    log_output "  redis-benchmark   Ferramenta de benchmark"
}

# Main installation function
install_redis() {
    if check_installation; then
        log_info "Redis CLI $(get_current_version) já está instalado."
        log_info "Use 'susa setup redis update' para atualizar."
        exit 0
    fi

    log_info "Iniciando instalação do Redis CLI..."

    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local install_result=1

    case "$os_name" in
        darwin)
            install_redis_macos
            install_result=$?
            ;;
        linux)
            local distro="$(get_distro_id)"
            log_debug "Distribuição detectada: $distro"

            case "$distro" in
                ubuntu | debian | pop | linuxmint)
                    install_redis_debian
                    install_result=$?
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    install_redis_redhat
                    install_result=$?
                    ;;
                arch | manjaro)
                    install_redis_arch
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
            log_success "Redis CLI $installed_version instalado com sucesso!"
            register_or_update_software_in_lock "redis" "$installed_version"

            echo ""
            log_output "Próximos passos:"
            log_output "  1. Teste a instalação: ${LIGHT_CYAN}redis-cli --version${NC}"
            log_output "  2. Conecte a um servidor: ${LIGHT_CYAN}redis-cli -h hostname -p port${NC}"
            log_output "  3. Use ${LIGHT_CYAN}susa setup redis --help${NC} para mais comandos disponíveis"
        else
            log_error "Redis CLI foi instalado mas não está disponível no PATH"
            return 1
        fi
    else
        log_error "Falha na instalação do Redis CLI"
        return $install_result
    fi
}

# Main execution
main() {
    install_redis
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
