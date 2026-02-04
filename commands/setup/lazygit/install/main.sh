#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/homebrew.sh"
source "$LIB_DIR/github.sh"
source "$UTILS_DIR/common.sh"

# Show additional info in command help
show_complement_help() {
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Interface TUI simples para Git, facilitando operações comuns"
    log_output "  como commits, branches, merges e rebases via terminal"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup lazygit install              # Instala o Lazygit"
    log_output "  susa setup lazygit install -v           # Instala com saída detalhada"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Execute: ${LIGHT_CYAN}lazygit${NC} dentro de um repositório Git"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Interface interativa e intuitiva no terminal"
    log_output "  • Visualização de diffs, logs e branches"
    log_output "  • Suporte a staging, commits, push/pull"
    log_output "  • Gerenciamento de stashes e rebases"
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

# Install on Linux via GitHub Releases
install_linux() {
    log_info "Obtendo $SOFTWARE_NAME via GitHub Releases..."

    # Detect architecture
    local os_arch=$(github_detect_os_arch "standard")
    local os="${os_arch%:*}"
    local arch="${os_arch#*:}"

    # Map to release naming
    local release_os="Linux"
    local release_arch=""
    case "$arch" in
        x64) release_arch="x86_64" ;;
        arm64) release_arch="arm64" ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    # Get latest version
    local latest_version=$(github_get_latest_version "$GITHUB_REPO" "true")
    if [ -z "$latest_version" ]; then
        log_error "Não foi possível obter a versão mais recente"
        return 1
    fi

    log_info "Versão mais recente: v$latest_version"

    # Build download URL
    local filename="lazygit_${latest_version}_${release_os}_${release_arch}.tar.gz"
    local download_url="https://github.com/${GITHUB_REPO}/releases/download/v${latest_version}/${filename}"

    local temp_dir=$(mktemp -d)
    local archive_path="$temp_dir/$filename"

    # Download
    if ! github_download_release "$download_url" "$archive_path" "$SOFTWARE_NAME"; then
        rm -rf "$temp_dir"
        return 1
    fi

    # Extract and install
    log_info "Extraindo arquivo..."
    tar -xzf "$archive_path" -C "$temp_dir"

    # Install to user bin
    local install_dir="$HOME/.local/bin"
    mkdir -p "$install_dir"

    if [ -f "$temp_dir/$BIN_NAME" ]; then
        log_info "Instalando em $install_dir..."
        mv "$temp_dir/$BIN_NAME" "$install_dir/"
        chmod +x "$install_dir/$BIN_NAME"
    else
        log_error "Binário não encontrado no arquivo"
        rm -rf "$temp_dir"
        return 1
    fi

    rm -rf "$temp_dir"

    # Verify installation
    if command -v "$BIN_NAME" &> /dev/null; then
        export INSTALLED_VERSION="$latest_version"
        return 0
    else
        log_error "$install_dir não está no PATH"
        log_info "Adicione ao seu ~/.bashrc ou ~/.zshrc:"
        log_output "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        return 1
    fi
}

# Main function
main() {
    if check_installation; then
        local current_version=$(get_current_version)
        log_warning "$SOFTWARE_NAME já está instalado (versão: $current_version)"
        log_info "Use ${LIGHT_CYAN}susa setup lazygit update${NC} para atualizar"
        return 0
    fi

    log_info "Instalando $SOFTWARE_NAME..."

    local install_result=1
    if is_mac; then
        install_macos
        install_result=$?
    elif is_linux; then
        install_linux
        install_result=$?
    else
        log_error "Sistema operacional não suportado"
        return 1
    fi

    if [ $install_result -eq 0 ] && check_installation; then
        local installed_version=$(get_current_version)
        register_or_update_software_in_lock "lazygit" "$installed_version"
        log_success "✓ $SOFTWARE_NAME instalado com sucesso!"
        log_info "Execute: ${LIGHT_CYAN}lazygit${NC} dentro de um repositório Git"
    else
        log_error "✗ Falha ao instalar $SOFTWARE_NAME"
        return 1
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
