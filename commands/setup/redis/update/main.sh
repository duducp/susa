#!/usr/bin/env zsh

UTILS_DIR="$(dirname "$0")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/os.sh"
source "$UTILS_DIR/common.sh"
source "$UTILS_DIR/update.sh"

# Show additional info in command help
show_complement_help() {
    log_output "${LIGHT_GREEN}O que faz:${NC}"
    log_output "  Atualiza o Redis CLI para a versão mais recente disponível"
    log_output "  nos repositórios do sistema."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup redis update              # Atualiza o Redis CLI"
    log_output "  susa setup redis update -v           # Atualiza com saída detalhada"
}

# Main update function
update_redis() {
    if ! check_installation; then
        log_error "Redis CLI não está instalado."
        log_info "Use 'susa setup redis install' para instalar."
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Atualizando Redis CLI (versão atual: $current_version)..."

    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local update_result=1

    case "$os_name" in
        darwin)
            update_redis_macos
            update_result=$?
            ;;
        linux)
            local distro="$(get_distro_id)"
            log_debug "Distribuição detectada: $distro"

            case "$distro" in
                ubuntu | debian | pop | linuxmint)
                    update_redis_debian
                    update_result=$?
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    update_redis_redhat
                    update_result=$?
                    ;;
                arch | manjaro)
                    update_redis_arch
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
            register_or_update_software_in_lock "redis" "$new_version"

            if [ "$new_version" != "$current_version" ]; then
                log_success "Redis CLI atualizado de $current_version para $new_version!"
            else
                log_info "Redis CLI já está na versão mais recente ($current_version)"
            fi
        else
            log_error "Falha na atualização do Redis CLI"
            return 1
        fi
    else
        log_error "Falha na atualização do Redis CLI"
        return $update_result
    fi
}

# Main execution
main() {
    update_redis
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
