#!/usr/bin/env zsh
# VSCode Installation Utilities
# Functions for installing VS Code on different platforms

# Install VS Code on macOS using Homebrew
install_vscode_macos() {
    log_info "Instalando VS Code no macOS..."

    if ! homebrew_is_available; then
        log_error "Homebrew não está instalado. Instale-o primeiro:"
        log_output "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi

    if homebrew_is_installed "$VSCODE_HOMEBREW_CASK"; then
        log_info "Atualizando VS Code via Homebrew..."
        homebrew_update "$VSCODE_HOMEBREW_CASK" "VS Code" || true
    else
        log_info "Instalando VS Code via Homebrew..."
        homebrew_install "$VSCODE_HOMEBREW_CASK" "VS Code"
    fi

    return 0
}

# Install VS Code on Debian/Ubuntu
install_vscode_debian() {
    log_info "Instalando VS Code no Debian/Ubuntu..."

    log_info "Instalando dependências..."
    sudo apt-get install -y wget gpg apt-transport-https > /dev/null 2>&1

    log_info "Adicionando chave GPG da Microsoft..."
    wget -qO- $VSCODE_APT_KEY_URL | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

    log_info "Adicionando repositório..."
    echo "deb [arch=amd64,arm64,armhf] $VSCODE_APT_REPO stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

    log_info "Atualizando lista de pacotes..."
    sudo apt-get update > /dev/null 2>&1

    log_info "Instalando VS Code..."
    sudo apt-get install -y $VSCODE_DEB_PACKAGE > /dev/null 2>&1

    return $?
}

# Install VS Code on RHEL/Fedora/CentOS
install_vscode_rhel() {
    log_info "Instalando VS Code no RHEL/Fedora/CentOS..."

    log_info "Importando chave GPG da Microsoft..."
    sudo rpm --import $VSCODE_RPM_KEY_URL > /dev/null 2>&1

    log_info "Adicionando repositório..."
    sudo tee /etc/yum.repos.d/vscode.repo > /dev/null << EOF
[code]
name=Visual Studio Code
baseurl=$VSCODE_RPM_REPO_URL
enabled=1
gpgcheck=1
gpgkey=$VSCODE_RPM_KEY_URL
EOF

    log_info "Instalando VS Code..."
    if command -v dnf &> /dev/null; then
        sudo dnf install -y $VSCODE_RPM_PACKAGE > /dev/null 2>&1
    else
        sudo yum install -y $VSCODE_RPM_PACKAGE > /dev/null 2>&1
    fi

    return $?
}

# Install VS Code on Arch Linux
install_vscode_arch() {
    log_info "Instalando VS Code no Arch Linux..."

    if command -v yay &> /dev/null; then
        log_info "Instalando via yay..."
        yay -S --noconfirm $VSCODE_ARCH_AUR > /dev/null 2>&1
    elif command -v paru &> /dev/null; then
        log_info "Instalando via paru..."
        paru -S --noconfirm $VSCODE_ARCH_AUR > /dev/null 2>&1
    else
        log_info "Instalando via pacman (repositório comunitário)..."
        sudo pacman -S --noconfirm $VSCODE_ARCH_COMMUNITY > /dev/null 2>&1 || {
            log_warning "VS Code não encontrado no repositório oficial"
            log_info "Tentando instalar helper AUR..."
            log_error "Considere instalar yay ou paru primeiro:"
            log_output "  sudo pacman -S --needed git base-devel"
            log_output "  git clone https://aur.archlinux.org/yay.git"
            log_output "  cd yay && makepkg -si"
            return 1
        }
    fi

    return 0
}

# Install VS Code on Linux (dispatcher)
install_vscode_linux() {
    local distro=$(get_distro_id)
    log_debug "Distribuição detectada: $distro"

    case "$distro" in
        ubuntu | debian | pop | linuxmint | elementary)
            install_vscode_debian
            ;;
        fedora | rhel | centos | rocky | almalinux)
            install_vscode_rhel
            ;;
        arch | manjaro | endeavouros)
            install_vscode_arch
            ;;
        *)
            log_error "Distribuição não suportada: $distro"
            log_info "Visite https://code.visualstudio.com/docs/setup/linux para instruções manuais"
            return 1
            ;;
    esac

    return $?
}
