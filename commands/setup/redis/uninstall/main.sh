#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$UTILS_DIR/common.sh"
source "$UTILS_DIR/uninstall.sh"

# Show additional info in command help
show_complement_help() {
    log_output "${LIGHT_GREEN}O que faz:${NC}"
    log_output "  Remove completamente o Redis CLI do sistema."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup redis uninstall           # Desinstala o Redis CLI"
    log_output "  susa setup redis uninstall -y        # Desinstala sem confirmação"
    log_output "  susa setup redis uninstall -v        # Desinstala com saída detalhada"
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -y, --yes         Pula confirmação de desinstalação"
}

# Main uninstall function
uninstall_redis() {
    if ! check_installation; then
        log_info "Redis CLI não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)
    local skip_confirm=false

    # Parse arguments for --yes flag
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y | --yes)
                skip_confirm=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    # Ask for confirmation unless -y was provided
    if [ "$skip_confirm" = false ]; then
        log_output ""
        log_output "${YELLOW}Deseja realmente desinstalar o Redis CLI $current_version? (s/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    log_info "Desinstalando Redis CLI..."

    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local uninstall_result=1

    case "$os_name" in
        darwin)
            uninstall_redis_macos
            uninstall_result=$?
            ;;
        linux)
            local distro="$(get_distro_id)"
            log_debug "Distribuição detectada: $distro"

            case "$distro" in
                ubuntu | debian | pop | linuxmint)
                    uninstall_redis_debian
                    uninstall_result=$?
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    uninstall_redis_redhat
                    uninstall_result=$?
                    ;;
                arch | manjaro)
                    uninstall_redis_arch
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
            remove_software_in_lock "redis"
            log_success "Redis CLI desinstalado com sucesso!"
        else
            log_error "Falha ao desinstalar Redis CLI completamente"
            return 1
        fi
    else
        log_error "Falha na desinstalação do Redis CLI"
        return $uninstall_result
    fi
}

# Main execution
main() {
    uninstall_redis "$@"
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
