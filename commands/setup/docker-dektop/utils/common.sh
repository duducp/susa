#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source required libraries
source "$LIB_DIR/homebrew.sh"
source "$LIB_DIR/os.sh"

# Constants
DOCKER_DESKTOP_NAME="Docker Desktop"
DOCKER_DESKTOP_BIN_MAC="/Applications/Docker.app/Contents/MacOS/Docker Desktop"
DOCKER_DESKTOP_BIN_LINUX="/usr/bin/docker-desktop"
DOCKER_DESKTOP_HOMEBREW_CASK="docker"
DOCKER_DESKTOP_DEB_PACKAGE="docker-desktop"
DOCKER_DESKTOP_DOWNLOAD_BASE="https://desktop.docker.com"

# ============================================================================
# MANDATORY FUNCTIONS (Required by SUSA standards)
# ============================================================================

# Check if Docker Desktop is installed
check_installation() {
    if is_mac; then
        [ -d "/Applications/Docker.app" ]
    else
        command -v docker-desktop &> /dev/null || dpkg -l docker-desktop 2> /dev/null | grep -q '^ii'
    fi
}

# Get installed Docker Desktop version
get_current_version() {
    if check_installation; then
        if is_mac; then
            # Extract version from Docker.app plist
            if [ -f "/Applications/Docker.app/Contents/Info.plist" ]; then
                defaults read "/Applications/Docker.app/Contents/Info.plist" CFBundleShortVersionString 2> /dev/null || echo "desconhecida"
            else
                echo "desconhecida"
            fi
        else
            # Get version from dpkg or rpm
            if command -v dpkg &> /dev/null && dpkg -l docker-desktop 2> /dev/null | grep -q '^ii'; then
                dpkg -l docker-desktop 2> /dev/null | grep '^ii' | awk '{print $3}' | cut -d'-' -f1 || echo "desconhecida"
            elif command -v rpm &> /dev/null && rpm -q docker-desktop &> /dev/null; then
                rpm -q --queryformat '%{VERSION}' docker-desktop 2> /dev/null || echo "desconhecida"
            else
                echo "desconhecida"
            fi
        fi
    else
        echo "desconhecida"
    fi
}

# Get latest Docker Desktop version
get_latest_version() {
    if is_mac; then
        # No macOS, consultar o Homebrew para a última versão
        if command -v brew &> /dev/null; then
            local latest_version=$(brew info --cask docker 2> /dev/null | grep -E "^docker: " | awk '{print $2}')
            if [ -n "$latest_version" ]; then
                echo "$latest_version"
            else
                echo "N/A"
            fi
        else
            echo "N/A"
        fi
    else
        # No Linux, consultar a página de releases do Docker Desktop
        local latest_version=$(curl -fsSL "https://docs.docker.com/desktop/release-notes/" 2> /dev/null |
            grep -oP 'Docker Desktop \K[0-9]+\.[0-9]+\.[0-9]+' |
            head -n 1)

        if [ -n "$latest_version" ]; then
            echo "$latest_version"
        else
            echo "N/A"
        fi
    fi
}

# ============================================================================
# INSTALLATION FUNCTIONS
# ============================================================================

# Install Docker Desktop on macOS
install_docker_desktop_macos() {
    log_info "Instalando Docker Desktop no macOS..."

    # Check if Homebrew is installed
    if ! homebrew_is_available; then
        log_error "Homebrew não está instalado. Instale-o primeiro:"
        log_output "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi

    # Install or upgrade Docker Desktop
    if homebrew_is_installed "$DOCKER_DESKTOP_HOMEBREW_CASK"; then
        log_info "Atualizando Docker Desktop via Homebrew..."
        homebrew_update "$DOCKER_DESKTOP_HOMEBREW_CASK" "Docker Desktop" || true
    else
        log_info "Instalando Docker Desktop via Homebrew..."
        homebrew_install "$DOCKER_DESKTOP_HOMEBREW_CASK" "Docker Desktop"
    fi

    return 0
}

# Install Docker Desktop on Linux (Debian/Ubuntu)
install_docker_desktop_debian() {
    log_info "Instalando Docker Desktop no Debian/Ubuntu..."

    local arch=$(uname -m)
    case "$arch" in
        x86_64) arch="amd64" ;;
        aarch64 | arm64) arch="arm64" ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    # Download Docker Desktop package
    local download_url="${DOCKER_DESKTOP_DOWNLOAD_BASE}/linux/main/${arch}/docker-desktop-${arch}.deb"
    local output_file="/tmp/docker-desktop-${arch}.deb"

    log_info "Baixando Docker Desktop..."
    log_debug "URL: $download_url"

    if ! curl -fsSL "$download_url" -o "$output_file"; then
        log_error "Falha ao baixar Docker Desktop"
        return 1
    fi

    # Install package
    log_info "Instalando pacote..."
    if ! sudo apt-get install -y "$output_file" 2>&1 | while read -r line; do log_debug "apt: $line"; done; then
        log_error "Falha ao instalar Docker Desktop"
        rm -f "$output_file"
        return 1
    fi

    rm -f "$output_file"
    return 0
}

# Install Docker Desktop on Linux (Fedora/RHEL/CentOS)
install_docker_desktop_rhel() {
    log_info "Instalando Docker Desktop no Fedora/RHEL/CentOS..."

    local arch=$(uname -m)
    case "$arch" in
        x86_64) arch="x86_64" ;;
        aarch64 | arm64) arch="aarch64" ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    # Download Docker Desktop package
    local download_url="${DOCKER_DESKTOP_DOWNLOAD_BASE}/linux/main/${arch}/docker-desktop-${arch}.rpm"
    local output_file="/tmp/docker-desktop-${arch}.rpm"

    log_info "Baixando Docker Desktop..."
    log_debug "URL: $download_url"

    if ! curl -fsSL "$download_url" -o "$output_file"; then
        log_error "Falha ao baixar Docker Desktop"
        return 1
    fi

    # Install package
    log_info "Instalando pacote..."
    if command -v dnf &> /dev/null; then
        if ! sudo dnf install -y "$output_file" 2>&1 | while read -r line; do log_debug "dnf: $line"; done; then
            log_error "Falha ao instalar Docker Desktop"
            rm -f "$output_file"
            return 1
        fi
    else
        if ! sudo yum install -y "$output_file" 2>&1 | while read -r line; do log_debug "yum: $line"; done; then
            log_error "Falha ao instalar Docker Desktop"
            rm -f "$output_file"
            return 1
        fi
    fi

    rm -f "$output_file"
    return 0
}

# Install Docker Desktop on Arch Linux
install_docker_desktop_arch() {
    log_info "Instalando Docker Desktop no Arch Linux..."

    # Docker Desktop for Arch is available via AUR
    if command -v yay &> /dev/null; then
        log_info "Instalando via yay (AUR)..."
        yay -S --noconfirm docker-desktop 2>&1 | while read -r line; do log_debug "yay: $line"; done
    elif command -v paru &> /dev/null; then
        log_info "Instalando via paru (AUR)..."
        paru -S --noconfirm docker-desktop 2>&1 | while read -r line; do log_debug "paru: $line"; done
    else
        log_error "Nenhum helper AUR detectado (yay, paru)"
        log_info "Para instalar manualmente, visite:"
        log_output "  https://aur.archlinux.org/packages/docker-desktop"
        return 1
    fi

    return 0
}

# Install Docker Desktop on Linux
install_docker_desktop_linux() {
    local distro=$(get_distro_id)
    log_debug "Distribuição detectada: $distro"

    case "$distro" in
        ubuntu | debian | pop | linuxmint | elementary)
            install_docker_desktop_debian
            ;;
        fedora | rhel | centos | rocky | almalinux)
            install_docker_desktop_rhel
            ;;
        arch | manjaro | endeavouros)
            install_docker_desktop_arch
            ;;
        *)
            log_error "Distribuição não suportada: $distro"
            log_info "Visite https://docs.docker.com/desktop/install/linux-install/ para instruções manuais"
            return 1
            ;;
    esac

    return $?
}

# ============================================================================
# UPDATE FUNCTIONS
# ============================================================================

# Update Docker Desktop on macOS
update_docker_desktop_macos() {
    if ! homebrew_is_available; then
        log_error "Homebrew não está instalado"
        return 1
    fi

    log_info "Atualizando Docker Desktop via Homebrew..."
    homebrew_update "$DOCKER_DESKTOP_HOMEBREW_CASK" "Docker Desktop" || {
        log_info "Docker Desktop já está na versão mais recente"
        return 0
    }
}

# Update Docker Desktop on Linux
update_docker_desktop_linux() {
    log_info "Atualizando Docker Desktop no Linux..."

    local distro=$(get_distro_id)
    log_debug "Distribuição detectada: $distro"

    case "$distro" in
        ubuntu | debian | pop | linuxmint | elementary)
            # Reinstall latest version
            install_docker_desktop_debian
            ;;
        fedora | rhel | centos | rocky | almalinux)
            # Reinstall latest version
            install_docker_desktop_rhel
            ;;
        arch | manjaro | endeavouros)
            log_info "Atualizando via pacman/AUR..."
            if command -v yay &> /dev/null; then
                yay -Syu --noconfirm docker-desktop 2>&1 | while read -r line; do log_debug "yay: $line"; done
            elif command -v paru &> /dev/null; then
                paru -Syu --noconfirm docker-desktop 2>&1 | while read -r line; do log_debug "paru: $line"; done
            else
                sudo pacman -Syu --noconfirm docker-desktop 2>&1 | while read -r line; do log_debug "pacman: $line"; done
            fi
            ;;
        *)
            log_error "Distribuição não suportada: $distro"
            return 1
            ;;
    esac
}

# ============================================================================
# UNINSTALL FUNCTIONS
# ============================================================================

# Uninstall Docker Desktop on macOS
uninstall_docker_desktop_macos() {
    if homebrew_is_available; then
        log_info "Removendo Docker Desktop via Homebrew..."
        homebrew_uninstall "$DOCKER_DESKTOP_HOMEBREW_CASK" "Docker Desktop" 2> /dev/null || log_debug "Docker Desktop não instalado via Homebrew"
    fi

    # Remove manually if still exists
    if [ -d "/Applications/Docker.app" ]; then
        log_info "Removendo aplicativo..."
        sudo rm -rf "/Applications/Docker.app"
    fi
}

# Uninstall Docker Desktop on Linux
uninstall_docker_desktop_linux() {
    local distro=$(get_distro_id)
    log_debug "Distribuição detectada: $distro"

    case "$distro" in
        ubuntu | debian | pop | linuxmint | elementary)
            log_info "Removendo Docker Desktop via apt..."
            sudo apt-get purge -y $DOCKER_DESKTOP_DEB_PACKAGE 2>&1 | while read -r line; do log_debug "apt: $line"; done
            sudo apt-get autoremove -y 2>&1 | while read -r line; do log_debug "apt: $line"; done
            ;;
        fedora | rhel | centos | rocky | almalinux)
            log_info "Removendo Docker Desktop via dnf/yum..."
            if command -v dnf &> /dev/null; then
                sudo dnf remove -y docker-desktop 2>&1 | while read -r line; do log_debug "dnf: $line"; done
            else
                sudo yum remove -y docker-desktop 2>&1 | while read -r line; do log_debug "yum: $line"; done
            fi
            ;;
        arch | manjaro | endeavouros)
            log_info "Removendo Docker Desktop via pacman..."
            if command -v yay &> /dev/null; then
                yay -Rns --noconfirm docker-desktop 2>&1 | while read -r line; do log_debug "yay: $line"; done
            elif command -v paru &> /dev/null; then
                paru -Rns --noconfirm docker-desktop 2>&1 | while read -r line; do log_debug "paru: $line"; done
            else
                sudo pacman -Rns --noconfirm docker-desktop 2>&1 | while read -r line; do log_debug "pacman: $line"; done
            fi
            ;;
    esac
}

# Remove Docker Desktop data
remove_docker_desktop_data() {
    echo ""
    log_output "${YELLOW}Deseja remover também os dados do Docker Desktop (containers, imagens, volumes)? (s/N)${NC}"
    read -r response

    if [[ "$response" =~ ^[sSyY]$ ]]; then
        log_info "Removendo dados do Docker Desktop..."

        if is_mac; then
            rm -rf "$HOME/Library/Containers/com.docker.docker" 2> /dev/null || true
            rm -rf "$HOME/Library/Application Support/Docker Desktop" 2> /dev/null || true
            rm -rf "$HOME/Library/Group Containers/group.com.docker" 2> /dev/null || true
            rm -rf "$HOME/.docker" 2> /dev/null || true
        else
            rm -rf "$HOME/.docker" 2> /dev/null || true
            rm -rf "$HOME/.local/share/docker-desktop" 2> /dev/null || true
        fi

        log_success "Dados removidos"
    else
        log_info "Dados mantidos"
    fi
}
