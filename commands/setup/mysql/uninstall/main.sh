#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$UTILS_DIR/common.sh"
source "$UTILS_DIR/uninstall.sh"

SKIP_CONFIRM=false

# Show additional info in command help
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  -y, --yes     Pula confirmação de desinstalação"
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Remove o MySQL Client e todos os seus utilitários do sistema."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup mysql uninstall              # Desinstala com confirmação"
    log_output "  susa setup mysql uninstall -y           # Desinstala sem confirmação"
}

# Uninstall MySQL client
uninstall_mysql() {
    if ! check_installation; then
        log_info "MySQL Client não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)
    log_debug "Versão instalada detectada para remoção: $current_version"

    if [ "$SKIP_CONFIRM" = false ]; then
        log_output ""
        log_output "${YELLOW}Deseja realmente desinstalar o MySQL Client $current_version? (s/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    log_info "Desinstalando MySQL Client..."

    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local uninstall_result=1

    case "$os_name" in
        darwin)
            uninstall_mysql_macos
            uninstall_result=$?
            ;;
        linux)
            local distro="$(get_distro_id)"
            case "$distro" in
                ubuntu | debian | pop | linuxmint)
                    uninstall_mysql_debian
                    uninstall_result=$?
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    uninstall_mysql_redhat
                    uninstall_result=$?
                    ;;
                arch | manjaro)
                    uninstall_mysql_arch
                    uninstall_result=$?
                    ;;
                *)
                    log_error "Distribuição Linux não suportada: $distro"
                    return 1
                    ;;
            esac
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    if [ $uninstall_result -eq 0 ]; then
        if ! check_installation; then
            remove_software_in_lock "mysql"
            log_success "MySQL Client desinstalado com sucesso!"
        else
            log_error "Falha ao desinstalar MySQL Client completamente"
            return 1
        fi
    else
        return $uninstall_result
    fi
}

# Main function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y | --yes)
                SKIP_CONFIRM=true
                shift
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    uninstall_mysql
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
