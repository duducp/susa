#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/os.sh"
source "$UTILS_DIR/common.sh"
source "$UTILS_DIR/update.sh"

# Help function
show_complement_help() {
    log_output "${LIGHT_GREEN}O que faz:${NC}"
    log_output "  Atualiza o Visual Studio Code para a versão mais recente disponível"
    log_output "  nos repositórios oficiais da Microsoft ou Homebrew."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup vscode update           # Atualiza o VS Code"
    log_output "  susa setup vscode update -v        # Atualiza com saída detalhada"
}

# Update VS Code
update_vscode() {
    log_info "Atualizando VS Code..."

    if ! check_installation; then
        log_error "VS Code não está instalado. Use 'susa setup vscode install' para instalar."
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"

    # Detect OS and update
    case "$OS_TYPE" in
        macos)
            if ! homebrew_is_available; then
                log_error "Homebrew não está instalado"
                return 1
            fi

            log_info "Atualizando VS Code via Homebrew..."
            homebrew_update "$VSCODE_HOMEBREW_CASK" "VS Code" || {
                log_info "VS Code já está na versão mais recente"
                return 0
            }
            ;;
        debian | fedora)
            local distro=$(get_distro_id)
            log_debug "Distribuição detectada: $distro"

            case "$distro" in
                ubuntu | debian | pop | linuxmint | elementary)
                    update_vscode_debian
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    update_vscode_rhel
                    ;;
                arch | manjaro | endeavouros)
                    update_vscode_arch
                    ;;
                *)
                    log_error "Distribuição não suportada: $distro"
                    return 1
                    ;;
            esac
            ;;
        *)
            log_error "Sistema operacional não suportado: $OS_TYPE"
            return 1
            ;;
    esac

    # Verify update
    if check_installation; then
        local new_version=$(get_current_version)
        register_or_update_software_in_lock "$COMMAND_NAME" "$new_version"

        if [ "$current_version" = "$new_version" ]; then
            log_info "VS Code já estava na versão mais recente ($current_version)"
        else
            log_success "VS Code atualizado com sucesso para versão $new_version!"
        fi
    else
        log_error "Falha na atualização do VS Code"
        return 1
    fi
}

# Main function
main() {
    update_vscode
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
