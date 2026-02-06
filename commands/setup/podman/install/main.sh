#!/usr/bin/env zsh

UTILS_DIR="$(dirname "$0")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/homebrew.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/shell.sh"
source "$UTILS_DIR/common.sh"

# Main function
main() {
    if check_installation; then
        log_info "Podman $(get_current_version) já está instalado."
        log_output "Use ${LIGHT_CYAN}susa setup podman update${NC} para atualizar"
        exit 0
    fi

    log_info "Iniciando instalação do Podman..."

    # Detect OS and install
    if is_mac; then
        install_podman_macos
    else
        install_podman_linux
    fi

    local install_result=$?

    if [ $install_result -eq 0 ]; then
        # Verify installation
        if check_installation; then
            local installed_version=$(get_current_version)
            log_success "Podman $installed_version instalado com sucesso!"
            register_or_update_software_in_lock "$COMMAND_NAME" "$installed_version"
            echo ""
            echo "Próximos passos:"

            if is_mac; then
                log_output "  1. A máquina virtual do Podman foi iniciada"
                log_output "  2. Execute: ${LIGHT_CYAN}podman run hello-world${NC}"
            else
                log_output "  1. Reinicie o terminal ou execute: ${LIGHT_CYAN}source $(detect_shell_config)${NC}"
                log_output "  2. Verifique o serviço: ${LIGHT_CYAN}systemctl --user status podman.socket${NC}"
                log_output "  3. Se necessário, inicie: ${LIGHT_CYAN}systemctl --user start podman.socket${NC}"
                log_output "  4. Teste a instalação: ${LIGHT_CYAN}$PODMAN_BIN_NAME run hello-world${NC}"
            fi

            log_output ""
            log_output "  💡 Use ${LIGHT_CYAN}susa setup podman --help${NC} para mais informações"
        else
            log_error "Podman foi instalado mas não está disponível no PATH"
            return 1
        fi
    else
        return $install_result
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
