#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

# Show additional info in command help
show_complement_help() {
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Cursor é um editor de código moderno com inteligência artificial integrada."
    log_output "  Fork do VS Code com recursos avançados de IA para desenvolvimento."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup cursor install              # Instala o Cursor"
    log_output "  susa setup cursor install -v           # Instala com saída detalhada"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Execute: ${LIGHT_CYAN}cursor${NC} ou abra pelo menu de aplicações"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Completação de código com IA"
    log_output "  • Chat integrado sobre seu código"
    log_output "  • Refatoração automática inteligente"
    log_output "  • Compatível com extensões do VS Code"
}

# Install on macOS
install_macos() {
    if ! homebrew_is_installed "$HOMEBREW_PACKAGE"; then
        homebrew_install "$HOMEBREW_PACKAGE" "$SOFTWARE_NAME"
    else
        log_warning "$SOFTWARE_NAME já está instalado via Homebrew"
    fi
    return 0
}

# Install on Linux
install_linux() {
    log_info "Obtendo informações da versão mais recente..."

    local latest_version=$(get_latest_version)

    if [ "$latest_version" = "unknown" ] || [ -z "$latest_version" ]; then
        log_warning "Não foi possível obter a versão mais recente"
        log_info "Prosseguindo com instalação da versão mais recente disponível..."
        latest_version="latest"
    else
        log_info "Versão disponível: $latest_version"
    fi

    # Detectar arquitetura
    local arch=$(uname -m)
    local download_arch=""

    case "$arch" in
        x86_64)
            download_arch="x64"
            ;;
        aarch64 | arm64)
            download_arch="arm64"
            ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    log_debug "Arquitetura detectada: $download_arch"

    # Detectar tipo de pacote (deb para Debian/Ubuntu, rpm para Fedora/RHEL, tar.gz genérico)
    local package_type=""
    local package_ext=""

    if is_linux_debian; then
        package_type="deb"
        package_ext=".deb"
        log_debug "Sistema baseado em Debian/Ubuntu detectado"
    elif is_linux_redhat; then
        package_type="rpm"
        package_ext=".rpm"
        log_debug "Sistema baseado em RedHat/Fedora detectado"
    else
        package_type=""
        package_ext=".tar.gz"
        log_debug "Usando pacote genérico tar.gz"
    fi

    # Construir URL de download
    local download_url="${CURSOR_BASE_URL}/linux-${download_arch}${package_type:+-$package_type}/cursor/${latest_version}"
    local temp_file="/tmp/cursor${package_ext}"

    log_debug "URL de download: $download_url"
    log_debug "Arquivo temporário: $temp_file"

    # Download
    log_info "Baixando $SOFTWARE_NAME..."
    if ! curl -fsSL "$download_url" -o "$temp_file"; then
        log_error "Falha ao baixar $SOFTWARE_NAME"
        log_output "URL: $download_url"
        log_output "Visite: ${LIGHT_CYAN}https://cursor.com${NC} para download manual"
        return 1
    fi

    # Instalar baseado no tipo de pacote
    log_info "Instalando $SOFTWARE_NAME..."

    if [ "$package_type" = "deb" ]; then
        # Instalar .deb com dpkg
        if ! sudo dpkg -i "$temp_file" 2>&1 | grep -v "warning"; then
            log_warning "Corrigindo dependências..."
            sudo apt-get install -f -y
        fi
        rm -f "$temp_file"

    elif [ "$package_type" = "rpm" ]; then
        # Instalar .rpm com dnf/yum
        local pkg_manager=$(get_redhat_pkg_manager)
        if ! sudo "$pkg_manager" install -y "$temp_file"; then
            log_error "Falha ao instalar pacote RPM"
            rm -f "$temp_file"
            return 1
        fi
        rm -f "$temp_file"

    else
        # Extrair tar.gz para /opt ou ~/.local
        local install_dir="$HOME/.local/cursor"
        mkdir -p "$install_dir"

        if ! tar -xzf "$temp_file" -C "$install_dir" --strip-components=1; then
            log_error "Falha ao extrair $SOFTWARE_NAME"
            rm -f "$temp_file"
            return 1
        fi

        rm -f "$temp_file"

        # Criar symlink em ~/.local/bin
        local bin_dir="$HOME/.local/bin"
        mkdir -p "$bin_dir"
        ln -sf "$install_dir/cursor" "$bin_dir/cursor"

        # Verificar se ~/.local/bin está no PATH
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            log_warning "$HOME/.local/bin não está no PATH"
            log_output "Adicione ao seu shell RC (~/.zshrc ou ~/.bashrc):"
            log_output "  ${LIGHT_CYAN}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
        fi
    fi

    log_success "$SOFTWARE_NAME instalado com sucesso!"
    return 0
}

# Main function
main() {
    if check_installation; then
        log_info "$SOFTWARE_NAME $(get_current_version) já está instalado."
        log_output ""
        log_output "Use ${LIGHT_CYAN}susa setup cursor update${NC} para atualizar"
        return 0
    fi

    log_info "Iniciando instalação do $SOFTWARE_NAME..."

    if is_mac; then
        install_macos
    else
        install_linux
    fi

    local install_result=$?

    if [ $install_result -eq 0 ]; then
        if check_installation; then
            local installed_version=$(get_current_version)
            register_or_update_software_in_lock "cursor" "$installed_version"

            log_success "$SOFTWARE_NAME $installed_version instalado com sucesso!"
            log_output ""
            log_output "Próximos passos:"
            log_output "  Execute: ${LIGHT_CYAN}cursor${NC}"
            log_output "  Ou abra pelo menu de aplicações"
        else
            log_error "$SOFTWARE_NAME foi instalado mas não está acessível"
            log_output "Verifique se $HOME/.local/bin está no seu PATH"
            return 1
        fi
    else
        return $install_result
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
