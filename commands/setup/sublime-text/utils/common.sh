#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# Source required libraries
source "$LIB_DIR/homebrew.sh"
source "$LIB_DIR/os.sh"

# Constants
SUBLIME_NAME="Sublime Text"
SUBLIME_BIN_NAME="subl"
SUBLIME_HOMEBREW_CASK="sublime-text"
SUBLIME_APT_KEY_URL="https://download.sublimetext.com/sublimehq-pub.gpg"
SUBLIME_APT_REPO="https://download.sublimetext.com/"
SUBLIME_RPM_KEY_URL="https://download.sublimetext.com/sublimehq-rpm-pub.gpg"
SUBLIME_DEB_PACKAGE="sublime-text"
SUBLIME_RPM_PACKAGE="sublime-text"
SUBLIME_ARCH_AUR="sublime-text-4"
SUBLIME_ARCH_COMMUNITY="sublime-text-dev"

# ============================================================================
# MANDATORY FUNCTIONS (Required by SUSA standards)
# ============================================================================

# Check if Sublime Text is installed
check_installation() {
    command -v $SUBLIME_BIN_NAME &> /dev/null
}

# Get installed Sublime Text version
get_current_version() {
    if check_installation; then
        local version=$($SUBLIME_BIN_NAME --version 2> /dev/null | grep -oE '[0-9]+' | head -1 || echo "desconhecida")
        if [ "$version" != "desconhecida" ]; then
            echo "$version"
        fi
    else
        echo "desconhecida"
    fi
}

# Get latest version from Sublime Text API
get_latest_version() {
    local api_url="https://www.sublimetext.com/updates/4/stable_update_check"
    local latest_version

    # Usa jq para extrair o campo latest_version corretamente
    if command -v jq &> /dev/null; then
        latest_version=$(curl -fsSL "$api_url" | jq -r '.latest_version // empty')
    else
        # Fallback para grep se jq não estiver disponível
        latest_version=$(curl -fsSL "$api_url" | grep -oE '"latest_version"\s*:\s*"[^"]+"' | head -1 | sed -E 's/.*: *"([^"]+)"/\1/')
    fi

    if [ -n "$latest_version" ]; then
        echo "$latest_version"
        return 0
    fi

    echo "N/A"
}

# ============================================================================
# INSTALLATION FUNCTIONS
# ============================================================================

# Install Sublime Text on macOS using Homebrew
install_sublime_macos() {
    log_info "Instalando Sublime Text no macOS..."

    # Check if Homebrew is installed
    if ! homebrew_is_available; then
        log_error "Homebrew não está instalado. Instale-o primeiro:"
        log_output "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi

    # Install or upgrade Sublime Text
    if homebrew_is_installed "$SUBLIME_HOMEBREW_CASK"; then
        log_info "Atualizando Sublime Text via Homebrew..."
        homebrew_update "$SUBLIME_HOMEBREW_CASK" "Sublime Text" || true
    else
        log_info "Instalando Sublime Text via Homebrew..."
        homebrew_install "$SUBLIME_HOMEBREW_CASK" "Sublime Text"
    fi

    return 0
}

# Install Sublime Text on Debian/Ubuntu
install_sublime_debian() {
    log_info "Instalando Sublime Text no Debian/Ubuntu..."

    # Install GPG key
    log_info "Adicionando chave GPG..."
    wget -qO - $SUBLIME_APT_KEY_URL | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null

    log_info "Adicionando repositório..."
    echo "deb $SUBLIME_APT_REPO apt/stable/" | sudo tee /etc/apt/sources.list.d/${SUBLIME_DEB_PACKAGE}.list > /dev/null

    log_info "Atualizando lista de pacotes..."
    sudo apt-get update > /dev/null 2>&1

    log_info "Instalando Sublime Text..."
    sudo apt-get install -y $SUBLIME_DEB_PACKAGE > /dev/null 2>&1

    return $?
}

# Install Sublime Text on RHEL/Fedora/CentOS
install_sublime_rhel() {
    log_info "Instalando Sublime Text no RHEL/Fedora/CentOS..."

    # Import GPG key
    log_info "Importando chave GPG..."
    sudo rpm -v --import $SUBLIME_RPM_KEY_URL > /dev/null 2>&1

    log_info "Adicionando repositório..."
    sudo tee /etc/yum.repos.d/${SUBLIME_RPM_PACKAGE}.repo > /dev/null << EOF
[$SUBLIME_RPM_PACKAGE]
name=Sublime Text
baseurl=https://download.sublimetext.com/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=$SUBLIME_RPM_KEY_URL
EOF

    log_info "Instalando Sublime Text..."
    if command -v dnf &> /dev/null; then
        sudo dnf install -y $SUBLIME_RPM_PACKAGE > /dev/null 2>&1
    else
        sudo yum install -y $SUBLIME_RPM_PACKAGE > /dev/null 2>&1
    fi

    return $?
}

# Install Sublime Text on Arch Linux
install_sublime_arch() {
    log_info "Instalando Sublime Text no Arch Linux..."

    # Install from AUR (requires yay or another AUR helper)
    if command -v yay &> /dev/null; then
        log_info "Instalando via yay (AUR)..."
        yay -S --noconfirm $SUBLIME_ARCH_AUR > /dev/null 2>&1
    elif command -v paru &> /dev/null; then
        log_info "Instalando via paru (AUR)..."
        paru -S --noconfirm $SUBLIME_ARCH_AUR > /dev/null 2>&1
    else
        log_warning "Nenhum helper AUR detectado (yay, paru)"
        log_info "Instalando manualmente via pacman (repositório comunitário)..."
        sudo pacman -S --noconfirm $SUBLIME_ARCH_COMMUNITY > /dev/null 2>&1 || {
            log_error "Falha ao instalar. Considere instalar um helper AUR como yay:"
            log_output "  sudo pacman -S --needed git base-devel"
            log_output "  git clone https://aur.archlinux.org/yay.git"
            log_output "  cd yay && makepkg -si"
            return 1
        }
    fi

    return 0
}

# Install Sublime Text on Linux
install_sublime_linux() {
    local distro=$(get_distro_id)
    log_debug "Distribuição detectada: $distro"

    case "$distro" in
        ubuntu | debian | pop | linuxmint | elementary)
            install_sublime_debian
            ;;
        fedora | rhel | centos | rocky | almalinux)
            install_sublime_rhel
            ;;
        arch | manjaro | endeavouros)
            install_sublime_arch
            ;;
        *)
            log_error "Distribuição não suportada: $distro"
            log_info "Visite https://www.sublimetext.com/docs/linux_repositories.html para instruções manuais"
            return 1
            ;;
    esac

    return $?
}

# ============================================================================
# UPDATE FUNCTIONS
# ============================================================================

# Update Sublime Text on macOS
update_sublime_macos() {
    if ! homebrew_is_available; then
        log_error "Homebrew não está instalado"
        return 1
    fi

    log_info "Atualizando Sublime Text via Homebrew..."
    homebrew_update "$SUBLIME_HOMEBREW_CASK" "Sublime Text" || {
        log_info "Sublime Text já está na versão mais recente"
        return 0
    }
}

# Update Sublime Text on Linux
update_sublime_linux() {
    local distro=$(get_distro_id)
    log_debug "Distribuição detectada: $distro"

    case "$distro" in
        ubuntu | debian | pop | linuxmint | elementary)
            log_info "Atualizando Sublime Text via apt..."
            sudo apt-get update > /dev/null 2>&1
            sudo apt-get install --only-upgrade -y $SUBLIME_DEB_PACKAGE > /dev/null 2>&1
            ;;
        fedora | rhel | centos | rocky | almalinux)
            log_info "Atualizando Sublime Text via dnf/yum..."
            if command -v dnf &> /dev/null; then
                sudo dnf upgrade -y $SUBLIME_RPM_PACKAGE > /dev/null 2>&1
            else
                sudo yum update -y $SUBLIME_RPM_PACKAGE > /dev/null 2>&1
            fi
            ;;
        arch | manjaro | endeavouros)
            log_info "Atualizando Sublime Text via pacman/AUR..."
            if command -v yay &> /dev/null; then
                yay -Syu --noconfirm $SUBLIME_ARCH_AUR > /dev/null 2>&1
            elif command -v paru &> /dev/null; then
                paru -Syu --noconfirm $SUBLIME_ARCH_AUR > /dev/null 2>&1
            else
                sudo pacman -Syu --noconfirm $SUBLIME_ARCH_COMMUNITY > /dev/null 2>&1
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

# Uninstall Sublime Text on macOS
uninstall_sublime_macos() {
    if homebrew_is_available; then
        log_info "Removendo Sublime Text via Homebrew..."
        homebrew_uninstall "$SUBLIME_HOMEBREW_CASK" "Sublime Text" 2> /dev/null || log_debug "Sublime Text não instalado via Homebrew"
    fi
}

# Uninstall Sublime Text on Linux
uninstall_sublime_linux() {
    local distro=$(get_distro_id)
    log_debug "Distribuição detectada: $distro"

    case "$distro" in
        ubuntu | debian | pop | linuxmint | elementary)
            log_info "Removendo Sublime Text via apt..."
            sudo apt-get purge -y $SUBLIME_DEB_PACKAGE > /dev/null 2>&1
            sudo apt-get autoremove -y > /dev/null 2>&1

            # Remove repository
            sudo rm -f /etc/apt/sources.list.d/${SUBLIME_DEB_PACKAGE}.list
            sudo rm -f /etc/apt/trusted.gpg.d/sublimehq-archive.gpg
            ;;
        fedora | rhel | centos | rocky | almalinux)
            log_info "Removendo Sublime Text via dnf/yum..."
            if command -v dnf &> /dev/null; then
                sudo dnf remove -y sublime-text > /dev/null 2>&1
            else
                sudo yum remove -y sublime-text > /dev/null 2>&1
            fi

            # Remove repository
            sudo rm -f /etc/yum.repos.d/${SUBLIME_RPM_PACKAGE}.repo
            ;;
        arch | manjaro | endeavouros)
            log_info "Removendo Sublime Text via pacman..."
            if command -v yay &> /dev/null; then
                yay -Rns --noconfirm $SUBLIME_ARCH_AUR > /dev/null 2>&1 || sudo pacman -Rns --noconfirm $SUBLIME_ARCH_COMMUNITY > /dev/null 2>&1
            elif command -v paru &> /dev/null; then
                paru -Rns --noconfirm $SUBLIME_ARCH_AUR > /dev/null 2>&1 || sudo pacman -Rns --noconfirm $SUBLIME_ARCH_COMMUNITY > /dev/null 2>&1
            else
                sudo pacman -Rns --noconfirm $SUBLIME_ARCH_COMMUNITY > /dev/null 2>&1
            fi
            ;;
    esac
}

# Remove Sublime Text configuration and data
remove_sublime_data() {
    log_output ""
    log_output "${YELLOW}Deseja remover também as configurações e pacotes do Sublime Text? (s/N)${NC}"
    read -r response

    if [[ "$response" =~ ^[sSyY]$ ]]; then
        log_info "Removendo configurações..."

        if is_mac; then
            rm -rf "$HOME/Library/Application Support/Sublime Text" 2> /dev/null || true
            rm -rf "$HOME/Library/Caches/Sublime Text" 2> /dev/null || true
        else
            rm -rf "$HOME/.config/sublime-text" 2> /dev/null || true
            rm -rf "$HOME/.config/sublime-text-3" 2> /dev/null || true
            rm -rf "$HOME/.cache/sublime-text" 2> /dev/null || true
        fi

        log_info "Configurações removidas"
    else
        log_info "Configurações mantidas"
    fi
}
