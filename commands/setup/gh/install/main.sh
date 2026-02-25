#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/homebrew.sh"
source "$LIB_DIR/sudo.sh"
source "$UTILS_DIR/common.sh"

# Show additional info in command help
show_complement_help() {
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Ferramenta oficial de linha de comando do GitHub que permite"
    log_output "  gerenciar issues, PRs, repositórios e mais diretamente do terminal"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup gh install                   # Instala o GitHub CLI"
    log_output "  susa setup gh install -v                # Instala com saída detalhada"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Execute: ${LIGHT_CYAN}gh auth login${NC} para autenticar sua conta GitHub"
    log_output "  Execute: ${LIGHT_CYAN}gh repo list${NC} para listar seus repositórios"
    log_output "  Execute: ${LIGHT_CYAN}gh repo list <OWNER>${NC} para listar os repositórios de um usuário ou organização"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Gerenciamento de issues e pull requests"
    log_output "  • Criação e clonagem de repositórios"
    log_output "  • Execução de GitHub Actions"
    log_output "  • Extensões customizadas"
}

# Install on macOS
install_macos() {
    if ! homebrew_is_installed "$HOMEBREW_FORMULA"; then
        homebrew_install "$HOMEBREW_FORMULA" "$SOFTWARE_NAME"
    else
        log_warning "$SOFTWARE_NAME já está instalado via Homebrew"
    fi
    return 0
}

# Install on Linux
install_linux() {
    local distro=$(get_distro_id)

    case "$distro" in
        ubuntu | debian)
            log_info "Configurando repositório oficial do GitHub CLI..."

            # Add GitHub CLI repository
            ensure_sudo

            # Install dependencies
            sudo apt-get update
            sudo apt-get install -y curl gnupg

            # Add GPG key
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

            # Add repository
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

            # Install
            sudo apt-get update
            sudo apt-get install -y gh
            ;;

        fedora | rhel | centos)
            log_info "Configurando repositório oficial do GitHub CLI..."
            ensure_sudo

            sudo dnf install -y 'dnf-command(config-manager)'
            sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
            sudo dnf install -y gh
            ;;

        arch | manjaro)
            log_info "Instalando via pacman..."
            ensure_sudo
            sudo pacman -Sy --noconfirm github-cli
            ;;

        opensuse*)
            log_info "Instalando via zypper..."
            ensure_sudo
            sudo zypper install -y gh
            ;;

        *)
            log_error "Distribuição não suportada: $distro"
            log_output "Consulte: ${LIGHT_CYAN}https://github.com/cli/cli/blob/trunk/docs/install_linux.md${NC}"
            return 1
            ;;
    esac

    return 0
}

# Main function
main() {
    if check_installation; then
        log_warning "$SOFTWARE_NAME já está instalado"
        local current_version=$(get_current_version)
        log_output "Versão atual: $current_version"
        log_output ""
        log_output "Para atualizar, use: ${LIGHT_CYAN}susa setup gh update${NC}"
        return 0
    fi

    log_info "Instalando $SOFTWARE_NAME..."

    if is_mac; then
        if ! install_macos; then
            log_error "Falha ao instalar $SOFTWARE_NAME no macOS"
            return 1
        fi
    elif is_linux; then
        if ! install_linux; then
            log_error "Falha ao instalar $SOFTWARE_NAME no Linux"
            return 1
        fi
    else
        log_error "Sistema operacional não suportado"
        return 1
    fi

    # Verify installation
    if ! check_installation; then
        log_error "Instalação falhou - comando $BIN_NAME não encontrado"
        return 1
    fi

    # Get installed version
    local installed_version=$(get_current_version)

    # Register in lock file
    register_or_update_software_in_lock "gh" "$installed_version"

    log_success "✓ $SOFTWARE_NAME instalado com sucesso!"
    log_output ""
    log_output "${LIGHT_GREEN}Próximos passos:${NC}"
    log_output "  1. Execute: ${LIGHT_CYAN}gh auth login${NC}"
    log_output "  2. Execute: ${LIGHT_CYAN}gh repo list${NC}"
    log_output ""
    log_output "Para mais informações: ${LIGHT_CYAN}gh --help${NC}"
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
