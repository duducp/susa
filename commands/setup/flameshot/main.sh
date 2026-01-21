#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/homebrew.sh"
source "$LIB_DIR/flatpak.sh"
source "$LIB_DIR/os.sh"

# Constants
FLAMESHOT_NAME="Flameshot"
FLAMESHOT_HOMEBREW_FORMULA="flameshot"
FLATPAK_APP_ID="org.flameshot.Flameshot"

SKIP_CONFIRM=false

# Help function
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  --uninstall       Desinstala o Flameshot do sistema"
    log_output "  -y, --yes         Pula confirmação (usar com --uninstall)"
    log_output "  -u, --upgrade     Atualiza o Flameshot para a versão mais recente"
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  $FLAMESHOT_NAME é uma ferramenta poderosa e simples de captura de tela."
    log_output "  Oferece recursos de anotação, edição e compartilhamento de screenshots"
    log_output "  com interface intuitiva e atalhos de teclado customizáveis."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup flameshot              # Instala o $FLAMESHOT_NAME"
    log_output "  susa setup flameshot --upgrade    # Atualiza o $FLAMESHOT_NAME"
    log_output "  susa setup flameshot --uninstall  # Desinstala o $FLAMESHOT_NAME"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  O Flameshot estará disponível no menu de aplicativos ou via:"
    log_output "    flameshot gui           # Abre captura interativa"
    log_output "    flameshot full          # Captura tela inteira"
    log_output "    flameshot screen        # Captura tela específica"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Captura de tela com seleção de área"
    log_output "  • Editor de imagens integrado"
    log_output "  • Anotações: setas, linhas, texto, formas"
    log_output "  • Desfoque e pixelização de áreas"
    log_output "  • Upload para Imgur"
    log_output "  • Atalhos de teclado customizáveis"
    log_output "  • Suporte a multi-monitor"
    log_output ""
    log_output "${LIGHT_GREEN}Configuração de atalho (Linux):${NC}"
    log_output "  Configure um atalho global (ex: Print Screen) para executar:"
    log_output "    flameshot gui"
}

# Get latest version
get_latest_version() {
    if is_mac; then
        homebrew_get_latest_version "$FLAMESHOT_HOMEBREW_FORMULA"
    else
        flatpak_get_latest_version "$FLATPAK_APP_ID"
    fi
}

# Get installed Flameshot version
get_current_version() {
    if check_installation; then
        if is_mac; then
            homebrew_get_installed_version "$FLAMESHOT_HOMEBREW_FORMULA"
        else
            flatpak_get_installed_version "$FLATPAK_APP_ID"
        fi
    else
        echo "desconhecida"
    fi
}

# Check if Flameshot is installed
check_installation() {
    if is_mac; then
        homebrew_is_installed "$FLAMESHOT_HOMEBREW_FORMULA"
    else
        flatpak_is_installed "$FLATPAK_APP_ID"
    fi
}

# Install Flameshot on macOS using Homebrew
install_flameshot_macos() {
    if ! homebrew_is_installed "$FLAMESHOT_HOMEBREW_FORMULA"; then
        homebrew_install "$FLAMESHOT_HOMEBREW_FORMULA" "$FLAMESHOT_NAME"
    else
        log_warning "Flameshot já está instalado via Homebrew"
    fi
    return 0
}

# Install Flameshot on Debian/Ubuntu
# Install Flameshot on Linux using Flatpak
install_flameshot_linux() {
    flatpak_install "$FLATPAK_APP_ID" "$FLAMESHOT_NAME"
    return $?
}

# Legacy function - kept for compatibility but not used
install_flameshot_debian() {
    log_info "Instalando Flameshot no Debian/Ubuntu..."

    # Get latest version from GitHub
    log_info "Buscando última versão do Flameshot..."
    local version=$(github_get_latest_version "$FLAMESHOT_GITHUB_REPO")

    if [ -z "$version" ]; then
        log_error "Não foi possível obter a versão mais recente"
        return 1
    fi

    log_info "Versão mais recente: $version"

    # Determine architecture and OS version
    local arch=$(uname -m)
    local deb_pattern=""

    case "$arch" in
        x86_64)
            # Try to detect Ubuntu/Debian version for best compatibility
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                if [ "$ID" = "ubuntu" ]; then
                    # Use Ubuntu 22.04 build as it's compatible with most versions
                    deb_pattern="ubuntu-22.04.amd64.deb"
                else
                    # Use Debian 12 build for Debian-based systems
                    deb_pattern="debian-12.amd64.deb"
                fi
            else
                deb_pattern="ubuntu-22.04.amd64.deb"
            fi
            ;;
        aarch64)
            log_error "Arquitetura ARM64 não tem builds .deb pré-compilados disponíveis"
            log_info "Recomendado: use Flatpak ou compile do código-fonte"
            return 1
            ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    # Construct download URL
    local download_url="https://github.com/${FLAMESHOT_GITHUB_REPO}/releases/download/${version}/flameshot-${version#v}-1.${deb_pattern}"

    log_debug "URL de download: $download_url"

    # Create temporary directory
    local temp_dir=$(mktemp -d)
    local deb_file="$temp_dir/flameshot.deb"

    # Download Flameshot
    if ! github_download_release "$download_url" "$deb_file" "Flameshot"; then
        log_error "Falha ao baixar Flameshot"
        rm -rf "$temp_dir"
        return 1
    fi

    # Install based on package manager
    if command -v apt-get &> /dev/null; then
        log_info "Instalando pacote .deb..."
        sudo apt-get install -y "$deb_file"
    elif command -v dpkg &> /dev/null; then
        log_info "Instalando pacote .deb..."
        sudo dpkg -i "$deb_file"
        sudo apt-get install -f -y 2> /dev/null || true
    else
        log_error "Sistema não suporta pacotes .deb"
        rm -rf "$temp_dir"
        return 1
    fi

    # Save version info
    sudo mkdir -p "$FLAMESHOT_INSTALL_DIR"
    echo "$version" | sudo tee "$FLAMESHOT_INSTALL_DIR/version.txt" > /dev/null 2>&1 || true

    # Cleanup
    rm -rf "$temp_dir"

    log_success "Flameshot instalado com sucesso!"
    log_output ""
    log_output "${LIGHT_CYAN}Para usar o Flameshot:${NC}"
    log_output "  • Via menu de aplicativos"
    log_output "  • Via terminal: ${LIGHT_GREEN}flameshot gui${NC}"
    log_output ""
    log_output "${LIGHT_CYAN}Configure atalho de teclado:${NC}"
    log_output "  Settings → Keyboard → Shortcuts → Custom Shortcuts"
    log_output "  Adicione: flameshot gui (recomendado: Print Screen)"
}

# Install Flameshot on RHEL/Fedora
install_flameshot_rhel() {
    log_info "Instalando Flameshot no RHEL/Fedora..."

    # Get latest version from GitHub
    log_info "Buscando última versão do Flameshot..."
    local version=$(github_get_latest_version "$FLAMESHOT_GITHUB_REPO")

    if [ -z "$version" ]; then
        log_error "Não foi possível obter a versão mais recente"
        return 1
    fi

    log_info "Versão mais recente: $version"

    # Determine architecture and Fedora version
    local arch=$(uname -m)
    local rpm_pattern=""

    case "$arch" in
        x86_64)
            # Try to detect Fedora version for best compatibility
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                # Use fc41 or fc42 based on detected version, default to fc41
                if [ -n "$VERSION_ID" ] && [ "$VERSION_ID" -ge 42 ]; then
                    rpm_pattern="fc42.x86_64.rpm"
                else
                    rpm_pattern="fc41.x86_64.rpm"
                fi
            else
                rpm_pattern="fc41.x86_64.rpm"
            fi
            ;;
        aarch64)
            log_error "Arquitetura ARM64 não tem builds .rpm pré-compilados disponíveis"
            log_info "Recomendado: use Flatpak ou compile do código-fonte"
            return 1
            ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    # Construct download URL
    local download_url="https://github.com/${FLAMESHOT_GITHUB_REPO}/releases/download/${version}/flameshot-${version#v}-1.${rpm_pattern}"

    log_debug "URL de download: $download_url"

    # Create temporary directory
    local temp_dir=$(mktemp -d)
    local rpm_file="$temp_dir/flameshot.rpm"

    # Download Flameshot
    if ! github_download_release "$download_url" "$rpm_file" "Flameshot"; then
        log_error "Falha ao baixar Flameshot"
        rm -rf "$temp_dir"
        return 1
    fi

    # Install based on package manager
    if command -v dnf &> /dev/null; then
        log_info "Instalando pacote .rpm via dnf..."
        sudo dnf install -y "$rpm_file"
    elif command -v yum &> /dev/null; then
        log_info "Instalando pacote .rpm via yum..."
        sudo yum install -y "$rpm_file"
    elif command -v rpm &> /dev/null; then
        log_info "Instalando pacote .rpm..."
        sudo rpm -i "$rpm_file"
    else
        log_error "Sistema não suporta pacotes .rpm"
        rm -rf "$temp_dir"
        return 1
    fi

    # Save version info
    sudo mkdir -p "$FLAMESHOT_INSTALL_DIR"
    echo "$version" | sudo tee "$FLAMESHOT_INSTALL_DIR/version.txt" > /dev/null 2>&1 || true

    # Cleanup
    rm -rf "$temp_dir"

    log_success "Flameshot instalado com sucesso!"
    log_output ""
    log_output "${LIGHT_CYAN}Para usar o Flameshot:${NC}"
    log_output "  • Via menu de aplicativos"
    log_output "  • Via terminal: ${LIGHT_GREEN}flameshot gui${NC}"
}

# Install Flameshot on Arch Linux
install_flameshot_arch() {
    log_info "Instalando Flameshot no Arch Linux..."

    # Check if yay or paru is available for AUR, otherwise use pacman
    if command -v pacman &> /dev/null; then
        log_info "Instalando via pacman..."
        sudo pacman -S --noconfirm flameshot
    elif command -v yay &> /dev/null; then
        log_info "Instalando via yay..."
        yay -S --noconfirm flameshot
    elif command -v paru &> /dev/null; then
        log_info "Instalando via paru..."
        paru -S --noconfirm flameshot
    else
        log_error "Pacman não encontrado"
        return 1
    fi

    log_success "Flameshot instalado com sucesso!"
    log_output ""
    log_output "${LIGHT_CYAN}Para usar o Flameshot:${NC}"
    log_output "  • Via menu de aplicativos"
    log_output "  • Via terminal: ${LIGHT_GREEN}flameshot gui${NC}"
}

# Main installation function
install_flameshot() {
    if check_installation; then
        log_info "Flameshot $(get_current_version) já está instalado."
        exit 0
    fi

    log_info "Iniciando instalação do Flameshot..."

    if is_mac; then
        install_flameshot_macos
    else
        install_flameshot_linux
    fi

    local install_result=$?

    if [ $install_result -eq 0 ]; then
        # Verify installation
        if check_installation; then
            local installed_version=$(get_current_version)

            # Mark as installed in lock file
            register_or_update_software_in_lock "$COMMAND_NAME" "$installed_version"

            log_success "Flameshot $installed_version instalado com sucesso!"
            log_output ""
            log_output "Próximos passos:"
            log_output "  1. Execute: ${LIGHT_CYAN}flameshot gui${NC} para abrir o capturador"
            log_output "  2. Configure um atalho global (ex: Print Screen)"
            log_output "  3. Use ${LIGHT_CYAN}susa setup flameshot --help${NC} para mais informações"
        else
            log_error "Flameshot foi instalado mas não está acessível"
            return 1
        fi
    else
        return $install_result
    fi
}

# Update Flameshot
update_flameshot() {
    log_info "Atualizando Flameshot..."

    if ! check_installation; then
        log_warning "Flameshot não está instalado. Execute sem --upgrade para instalar."
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"

    if is_mac; then
        if homebrew_is_installed "$FLAMESHOT_HOMEBREW_FORMULA"; then
            homebrew_update "$FLAMESHOT_HOMEBREW_FORMULA" "$FLAMESHOT_NAME"
        else
            log_error "Flameshot não está instalado via Homebrew"
            return 1
        fi
    else
        if flatpak_is_installed "$FLATPAK_APP_ID"; then
            flatpak_update "$FLATPAK_APP_ID" "$FLAMESHOT_NAME"
        else
            log_error "Flameshot não está instalado via Flatpak"
            return 1
        fi
    fi

    local new_version=$(get_current_version)

    # Update lock file
    register_or_update_software_in_lock "$COMMAND_NAME" "$new_version"

    if [ "$current_version" = "$new_version" ]; then
        log_info "Flameshot já estava na versão mais recente ($current_version)"
    else
        log_success "Flameshot atualizado com sucesso para versão $new_version!"
    fi
}

# Uninstall Flameshot
uninstall_flameshot() {
    log_info "Desinstalando Flameshot..."

    if ! check_installation; then
        log_info "Flameshot não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)
    log_debug "Versão a ser removida: $current_version"

    log_output ""
    if [ "$SKIP_CONFIRM" = false ]; then
        log_output "${YELLOW}Deseja realmente desinstalar o Flameshot $current_version? (s/N)${NC}"
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    if is_mac; then
        if homebrew_is_installed "$FLAMESHOT_HOMEBREW_FORMULA"; then
            homebrew_uninstall "$FLAMESHOT_HOMEBREW_FORMULA" "$FLAMESHOT_NAME"
        else
            log_warning "Flameshot não está instalado via Homebrew"
            return 1
        fi
    else
        if flatpak_is_installed "$FLATPAK_APP_ID"; then
            flatpak_uninstall "$FLATPAK_APP_ID" "$FLAMESHOT_NAME"
        else
            log_warning "Flameshot não está instalado via Flatpak"
            return 1
        fi
    fi

    # Verify uninstallation
    if ! check_installation; then
        # Remove from lock file
        remove_software_in_lock "$COMMAND_NAME"
        log_success "Flameshot desinstalado com sucesso!"
    else
        log_error "Falha ao desinstalar Flameshot completamente"
        return 1
    fi
}

# Main execution
main() {
    # Parse arguments
    local should_update=false
    local should_uninstall=false

    for arg in "$@"; do
        case "$arg" in
            --info)
                show_software_info
                exit 0
                ;;
            -y | --yes)
                SKIP_CONFIRM=true
                shift
                ;;
            -u | --upgrade)
                should_update=true
                ;;
            --uninstall)
                should_uninstall=true
                ;;
            *)
                log_error "Opção desconhecida: $arg"
                show_help
                exit 1
                ;;
        esac
    done

    # Execute requested action
    if [ "$should_uninstall" = true ]; then
        uninstall_flameshot
    elif [ "$should_update" = true ]; then
        update_flameshot
    else
        install_flameshot
    fi
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
