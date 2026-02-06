#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"

# Get utilities directory
UTILS_DIR="$(dirname "$(readlink -f "$0")")/../utils"
source "$UTILS_DIR/common.sh"

# Help function
show_complement_help() {
    log_output "${LIGHT_GREEN}Detalhes da instalação:${NC}"
    log_output "  • macOS: Instala via Homebrew Cask"
    log_output "  • Linux: Download e instalação do pacote oficial"
    log_output "    - Debian/Ubuntu: .deb"
    log_output "    - Fedora/RHEL: .rpm"
    log_output "    - Arch: AUR (via yay/paru)"
    log_output ""
    log_output "${LIGHT_GREEN}Requisitos:${NC}"
    log_output "  • macOS: macOS 11.0 (Big Sur) ou superior"
    log_output "  • Linux: Kernel 4.x ou superior, systemd"
    log_output ""
    log_output "${LIGHT_GREEN}⚠️  Nota sobre licenciamento:${NC}"
    log_output "  Docker Desktop requer licença para uso comercial em empresas"
    log_output "  com mais de 250 funcionários ou US$ 10 milhões em receita anual."
    log_output "  Para alternativa open source, use: ${LIGHT_CYAN}susa setup podman-desktop install${NC}"
}

# Main installation function
main() {
    if check_installation; then
        log_info "Docker Desktop $(get_current_version) já está instalado."
        exit 0
    fi

    # Mostrar aviso sobre licenciamento e alternativa
    echo ""
    log_output "${YELLOW}⚠️  Importante - Licenciamento Docker Desktop${NC}"
    echo ""
    log_output "O Docker Desktop possui requisitos de licenciamento para uso comercial."
    log_output "Empresas com mais de 250 funcionários ou US$ 10M+ em receita"
    log_output "precisam de uma assinatura paga."
    echo ""
    log_output "Para uma alternativa ${BOLD}open source${NC} e ${BOLD}gratuita${NC}, considere o ${LIGHT_CYAN}Podman Desktop${NC}:"
    log_output "  • Totalmente compatível com Docker"
    log_output "  • Interface gráfica similar"
    log_output "  • Sem restrições de licenciamento"
    log_output "  • Comando: ${LIGHT_CYAN}susa setup podman-desktop install${NC}"
    echo ""
    log_output "${YELLOW}Deseja continuar com a instalação do Docker Desktop? (s/N)${NC}"
    read -r response

    if [[ ! "$response" =~ ^[sSyY]$ ]]; then
        log_info "Instalação do Docker Desktop cancelada"
        echo ""
        log_output "Para instalar o Podman Desktop, execute: ${LIGHT_CYAN}susa setup podman-desktop install${NC}"
        exit 0
    fi

    log_info "Iniciando instalação do Docker Desktop..."

    # Detect OS and install
    if is_mac; then
        install_docker_desktop_macos
    else
        install_docker_desktop_linux
    fi

    local install_result=$?

    if [ $install_result -eq 0 ]; then
        # Verify installation
        if check_installation; then
            local installed_version=$(get_current_version)

            # Mark as installed in lock file
            register_or_update_software_in_lock "$COMMAND_NAME" "$installed_version"

            log_success "Docker Desktop $installed_version instalado com sucesso!"
            echo ""
            log_output "Próximos passos:"
            log_output "  1. Abra o Docker Desktop pelo menu de aplicativos"
            log_output "  2. Aguarde a inicialização (pode levar alguns minutos)"
            log_output "  3. Use ${LIGHT_CYAN}docker${NC} e ${LIGHT_CYAN}docker-compose${NC} normalmente"
        else
            log_error "Docker Desktop foi instalado mas não está disponível"
            return 1
        fi
    else
        return $install_result
    fi
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
