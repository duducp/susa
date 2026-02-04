#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/homebrew.sh"
source "$LIB_DIR/os.sh"
source "$UTILS_DIR/common.sh"

SKIP_CONFIRM=false

show_help() {
    show_description
    log_output ""
    show_usage "[options]"
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -y, --yes         Pula confirmação"
    log_output "  -h, --help        Mostra esta mensagem"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup docker uninstall        # Desinstala com confirmação"
    log_output "  susa setup docker uninstall -y     # Desinstala sem confirmação"
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y | --yes)
                SKIP_CONFIRM=true
                shift
                ;;
            -h | --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Check if Docker is installed
    if ! check_installation; then
        log_info "Docker não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)

    if [ "$SKIP_CONFIRM" = false ]; then
        log_output ""
        log_output "${YELLOW}Deseja realmente desinstalar o Docker $current_version? (s/N)${NC}"
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    if is_mac; then
        # Uninstall via Homebrew
        if homebrew_is_available; then
            homebrew_uninstall_formula "docker" "Docker" || log_debug "Docker não instalado via Homebrew"
            homebrew_uninstall_formula "docker-compose" "docker-compose" || log_debug "docker-compose não instalado"
        fi
    else
        # Detect Linux distribution
        local distro=$(get_distro_id)
        log_debug "Distribuição detectada: $distro"

        # Stop Docker service
        sudo systemctl stop docker > /dev/null 2>&1 || log_debug "Serviço já parado"
        sudo systemctl disable docker > /dev/null 2>&1 || log_debug "Serviço não estava habilitado"

        case "$distro" in
            ubuntu | debian | pop | linuxmint)
                sudo apt-get purge -y \
                    docker-ce \
                    docker-ce-cli \
                    containerd.io \
                    docker-buildx-plugin \
                    docker-compose-plugin > /dev/null 2>&1
                sudo apt-get autoremove -y > /dev/null 2>&1
                ;;
            fedora | rhel | centos | rocky | almalinux)
                sudo dnf remove -y \
                    docker-ce \
                    docker-ce-cli \
                    containerd.io \
                    docker-buildx-plugin \
                    docker-compose-plugin > /dev/null 2>&1
                ;;
            arch | manjaro)
                sudo pacman -Rns --noconfirm docker docker-compose > /dev/null 2>&1
                ;;
        esac

        # Remove user from docker group
        local current_user=$(whoami)
        if groups "$current_user" | grep -q docker; then
            sudo gpasswd -d "$current_user" docker > /dev/null 2>&1 || log_debug "Não foi possível remover do grupo"
        fi
    fi

    # Verify uninstallation
    if ! check_installation; then
        # Mark as uninstalled in lock file
        remove_software_in_lock "docker"

        log_success "Docker desinstalado com sucesso!"
    else
        log_error "Falha ao desinstalar Docker completamente"
        return 1
    fi

    # Ask about removing Docker data (images, containers, volumes)
    if [ "$SKIP_CONFIRM" = false ]; then
        log_output ""
        log_output "${YELLOW}Deseja remover também as imagens, containers e volumes do Docker? (s/N)${NC}"
        read -r response

        if [[ "$response" =~ ^[sSyY]$ ]]; then
            log_info "Removendo dados do Docker..."

            # Remove Docker data directories
            if [ -d "/var/lib/docker" ]; then
                sudo rm -rf /var/lib/docker 2> /dev/null || log_debug "Não foi possível remover /var/lib/docker"
                log_debug "Diretório removido: /var/lib/docker"
            fi

            if [ -d "$HOME/.docker" ]; then
                rm -rf "$HOME/.docker" 2> /dev/null || true
                log_debug "Configurações removidas: ~/.docker"
            fi

            log_success "Dados do Docker removidos"
        else
            log_info "Dados do Docker mantidos"
        fi
    else
        # Auto-remove when --yes is used
        log_info "Removendo dados do Docker automaticamente..."

        if [ -d "/var/lib/docker" ]; then
            sudo rm -rf /var/lib/docker 2> /dev/null || log_debug "Não foi possível remover /var/lib/docker"
            log_debug "Diretório removido: /var/lib/docker"
        fi

        if [ -d "$HOME/.docker" ]; then
            rm -rf "$HOME/.docker" 2> /dev/null || true
            log_debug "Configurações removidas: ~/.docker"
        fi

        log_info "Dados do Docker removidos automaticamente"
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
