#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/../utils"
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/homebrew.sh"
source "$LIB_DIR/os.sh"
source "$UTILS_DIR/common.sh"

DOCKER_HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

# Configure user to run Docker without sudo
configure_docker_group() {
    # Check if docker group exists
    if ! getent group docker &> /dev/null; then
        if ! sudo groupadd docker 2> /dev/null; then
            log_error "Falha ao criar grupo docker"
            return 1
        fi
    fi

    # Add current user to docker group
    local current_user=$(whoami)
    if ! groups "$current_user" | grep -q docker; then
        log_debug "Adicionando usuário $current_user ao grupo docker..."
        if ! sudo usermod -aG docker "$current_user" 2> /dev/null; then
            log_error "Falha ao adicionar usuário ao grupo docker"
            return 1
        fi
    else
        log_debug "Usuário já está no grupo docker"
    fi

    return 0
}

# Install Docker on macOS using Homebrew
install_docker_macos() {
    # Check if Homebrew is installed
    if ! homebrew_is_available; then
        log_error "Homebrew não está instalado. Instale-o primeiro:"
        log_output "  /bin/bash -c \"\$(curl -fsSL $DOCKER_HOMEBREW_INSTALL_URL)\""
        return 1
    fi

    # Install or upgrade Docker
    if homebrew_is_installed_formula "docker"; then
        homebrew_update_formula "docker" "Docker" || true
    else
        homebrew_install_formula "docker" "Docker"
    fi

    # Install docker-compose if not present
    if ! homebrew_is_installed_formula "docker-compose"; then
        homebrew_install_formula "docker-compose" "docker-compose" || log_debug "docker-compose não disponível via homebrew"
    fi

    return 0
}

# Install Docker on Linux
install_docker_linux() {
    # Detect Linux distribution
    local distro=$(get_distro_id)
    log_debug "Distribuição detectada: $distro"

    case "$distro" in
        ubuntu | debian | pop | linuxmint)
            install_docker_debian
            ;;
        fedora | rhel | centos | rocky | almalinux)
            install_docker_rhel
            ;;
        arch | manjaro)
            install_docker_arch
            ;;
        *)
            log_error "Distribuição não suportada: $distro"
            log_info "Visite https://docs.docker.com/engine/install/ para instruções manuais"
            return 1
            ;;
    esac

    local install_result=$?
    if [ $install_result -ne 0 ]; then
        return $install_result
    fi

    # Start and enable Docker service
    sudo systemctl enable docker > /dev/null 2>&1 || log_debug "Não foi possível habilitar serviço"
    sudo systemctl start docker > /dev/null 2>&1 || log_debug "Não foi possível iniciar serviço"

    # Configure user permissions
    configure_docker_group

    return 0
}

# Install Docker on Debian/Ubuntu based systems
install_docker_debian() {
    # Remove old versions
    sudo apt-get remove -y docker docker-engine docker.io containerd runc > /dev/null 2>&1 || true

    # Update package index
    sudo apt-get update > /dev/null 2>&1

    # Install dependencies
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release > /dev/null 2>&1

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    local distro
    distro=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
    curl -fsSL "$DOCKER_DOWNLOAD_BASE_URL/linux/${distro}/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg > /dev/null 2>&1
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Set up repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] $DOCKER_DOWNLOAD_BASE_URL/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') \
      $(lsb_release -cs) stable" |
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update package index again
    sudo apt-get update > /dev/null 2>&1

    # Install Docker Engine
    sudo apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin > /dev/null 2>&1

    return $?
}

# Install Docker on RHEL/Fedora based systems
install_docker_rhel() {
    # Remove old versions
    sudo dnf remove -y docker \
        docker-client \
        docker-client-latest \
        docker-common \
        docker-latest \
        docker-latest-logrotate \
        docker-logrotate \
        docker-engine > /dev/null 2>&1 || true

    # Install dependencies
    sudo dnf install -y dnf-plugins-core > /dev/null 2>&1

    # Add Docker repository
    sudo dnf config-manager --add-repo $DOCKER_DOWNLOAD_BASE_URL/linux/fedora/docker-ce.repo > /dev/null 2>&1

    # Install Docker Engine
    sudo dnf install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin > /dev/null 2>&1

    return $?
}

# Install Docker on Arch based systems
install_docker_arch() {
    # Install Docker
    sudo pacman -S --noconfirm docker docker-compose > /dev/null 2>&1

    return $?
}

main() {
    if check_installation; then
        log_info "Docker $(get_current_version) já está instalado."
        exit 0
    fi

    # Mostrar aviso sobre Podman
    echo ""
    log_output "${YELLOW}⚠️  Consideração Importante${NC}"
    echo ""
    log_output "Você está prestes a instalar o Docker. No entanto, recomendamos considerar o ${LIGHT_CYAN}Podman${NC}, que oferece diversas vantagens:"
    echo ""
    log_output "  ${LIGHT_GREEN}✓${NC} ${BOLD}Totalmente compatível com Docker${NC} (API e comandos)"
    log_output "  ${LIGHT_GREEN}✓${NC} ${BOLD}Sem daemon${NC} - mais seguro e leve"
    log_output "  ${LIGHT_GREEN}✓${NC} ${BOLD}Rootless${NC} - não requer privilégios de root"
    log_output "  ${LIGHT_GREEN}✓${NC} ${BOLD}Drop-in replacement${NC} - alias docker=podman funciona perfeitamente"
    log_output "  ${LIGHT_GREEN}✓${NC} ${BOLD}Open Source${NC} - sem preocupações com licenciamento"
    echo ""
    log_output "Para instalar o Podman ao invés do Docker, execute:"
    log_output "  ${LIGHT_CYAN}susa setup podman install${NC}"
    echo ""
    log_output "${YELLOW}Deseja realmente continuar com a instalação do Docker? (s/N)${NC}"
    read -r response

    if [[ ! "$response" =~ ^[sSyY]$ ]]; then
        log_info "Instalação do Docker cancelada"
        echo ""
        log_output "Para instalar o Podman, execute: ${LIGHT_CYAN}susa setup podman install${NC}"
        exit 0
    fi

    log_info "Iniciando instalação do Docker..."

    # Detect OS
    if is_mac; then
        install_docker_macos
    else
        install_docker_linux
    fi

    local install_result=$?

    if [ $install_result -eq 0 ]; then
        # Verify installation
        if check_installation; then
            local installed_version=$(get_current_version)

            # Mark as installed in lock file
            register_or_update_software_in_lock "docker" "$installed_version"

            log_success "Docker $installed_version instalado com sucesso!"
        else
            log_error "Docker foi instalado mas não está disponível no PATH"
            return 1
        fi
    else
        return $install_result
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
