#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$UTILS_DIR/common.sh"
source "$UTILS_DIR/update.sh"

# Show additional info in command help
show_complement_help() {
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Atualiza o PostgreSQL Client instalado para a versão mais recente disponível"
    log_output "  no gerenciador de pacotes do seu sistema operacional."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup postgres update              # Atualiza o PostgreSQL Client"
    log_output "  susa setup postgres update -v           # Atualiza com saída detalhada"
}

# Update PostgreSQL client
update_postgres() {
    if ! check_installation; then
        log_error "PostgreSQL Client não está instalado."
        log_output "Use ${LIGHT_CYAN}susa setup postgres install${NC} para instalar."
        return 1
    fi

    local current_version=$(get_current_version)
    log_debug "Versão atual detectada: $current_version"
    log_info "Atualizando PostgreSQL Client (versão atual: $current_version)..."

    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local update_result=1

    case "$os_name" in
        darwin)
            update_postgres_macos
            update_result=$?
            ;;
        linux)
            local distro="$(get_distro_id)"
            case "$distro" in
                ubuntu | debian | pop | linuxmint)
                    update_postgres_debian
                    update_result=$?
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    update_postgres_redhat
                    update_result=$?
                    ;;
                arch | manjaro)
                    update_postgres_arch
                    update_result=$?
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

    if [ $update_result -eq 0 ]; then
        if check_installation; then
            local new_version=$(get_current_version)
            register_or_update_software_in_lock "postgres" "$new_version"

            if [ "$new_version" != "$current_version" ]; then
                log_success "PostgreSQL Client atualizado de $current_version para $new_version!"
            else
                log_info "PostgreSQL Client já está na versão mais recente ($current_version)"
            fi
        else
            log_error "Falha na atualização do PostgreSQL Client"
            return 1
        fi
    else
        return $update_result
    fi
}

# Main execution
main() {
    update_postgres
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
