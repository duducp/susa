#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/homebrew.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/shell.sh"
source "$UTILS_DIR/common.sh"

# Detect OS and architecture
detect_os_and_arch() {
    local os_name
    if is_mac; then
        os_name="darwin"
    else
        os_name="linux"
    fi

    local arch=$(uname -m)

    case "$arch" in
        x86_64 | amd64) arch="x86_64" ;;
        aarch64 | arm64) arch="arm" ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    echo "${os_name}:${arch}"
}

# Get download filename for current system
get_download_filename() {
    local os_arch="$1"
    local os="${os_arch%%:*}"
    local arch="${os_arch##*:}"

    # Google Cloud SDK archive naming convention
    case "$os:$arch" in
        linux:x86_64)
            echo "google-cloud-cli-linux-x86_64.tar.gz"
            ;;
        linux:arm)
            echo "google-cloud-cli-linux-arm.tar.gz"
            ;;
        darwin:x86_64)
            echo "google-cloud-cli-darwin-x86_64.tar.gz"
            ;;
        darwin:arm)
            echo "google-cloud-cli-darwin-arm.tar.gz"
            ;;
        *)
            log_error "Combinação de OS/arquitetura não suportada: $os:$arch"
            return 1
            ;;
    esac
}

# Install Google Cloud SDK on macOS using Homebrew
install_gcloud_macos_brew() {
    log_info "Instalando Google Cloud SDK via Homebrew..."

    # Check if Homebrew is installed
    if ! homebrew_is_available; then
        log_warning "Homebrew não está instalado. Instalando via tarball..."
        return 1
    fi

    # Install or upgrade gcloud
    if homebrew_is_installed_formula "google-cloud-sdk"; then
        log_info "Atualizando Google Cloud SDK via Homebrew..."
        homebrew_update_formula "google-cloud-sdk" "Google Cloud SDK" || true
    else
        log_info "Instalando Google Cloud SDK via Homebrew..."
        homebrew_install_formula "google-cloud-sdk" "Google Cloud SDK"
    fi

    return 0
}

# Install Google Cloud SDK from tarball (Linux and macOS fallback)
install_gcloud_tarball() {
    local os_arch="$1"

    log_info "Instalando Google Cloud SDK via tarball..."

    # Get download filename
    local filename=$(get_download_filename "$os_arch")
    if [ $? -ne 0 ]; then
        return 1
    fi

    # Build download URL
    local download_url="${GCLOUD_SDK_BASE_URL}/${filename}"
    local output_file="/tmp/${filename}"

    log_info "Baixando Google Cloud SDK..."
    log_debug "URL: $download_url"

    # Download with retry
    if ! curl -fsSL --retry 3 --retry-delay 2 -o "$output_file" "$download_url"; then
        log_error "Falha ao baixar Google Cloud SDK"
        rm -f "$output_file"
        return 1
    fi

    # Extract to installation directory
    local install_dir="$HOME/.local/share/google-cloud-sdk"

    # Remove old installation if exists
    if [ -d "$install_dir" ]; then
        log_debug "Removendo instalação antiga..."
        rm -rf "$install_dir"
    fi

    mkdir -p "$(dirname "$install_dir")"

    log_info "Extraindo Google Cloud SDK..."
    if ! tar -xzf "$output_file" -C "$(dirname "$install_dir")" 2> /dev/null; then
        log_error "Falha ao extrair Google Cloud SDK"
        rm -f "$output_file"
        return 1
    fi
    rm -f "$output_file"

    # Run install script
    log_info "Configurando Google Cloud SDK..."
    local install_script="$install_dir/install.sh"

    if [ -f "$install_script" ]; then
        # Run installer non-interactively
        bash "$install_script" \
            --usage-reporting=false \
            --command-completion=true \
            --path-update=true \
            --quiet \
            2> /dev/null || log_debug "Instalador executado com avisos"
    else
        log_error "Script de instalação não encontrado"
        return 1
    fi

    # Configure PATH for current session
    export PATH="$install_dir/bin:$PATH"

    # Add to shell configuration
    local shell_config=$(detect_shell_config)
    local gcloud_path_line="export PATH=\"\$HOME/.local/share/google-cloud-sdk/bin:\$PATH\""

    if ! grep -q "google-cloud-sdk/bin" "$shell_config" 2> /dev/null; then
        echo "" >> "$shell_config"
        echo "# Google Cloud SDK" >> "$shell_config"
        echo "$gcloud_path_line" >> "$shell_config"
        log_debug "PATH configurado em $shell_config"
    fi

    return 0
}

main() {
    if check_installation; then
        log_info "Google Cloud SDK $(get_current_version) já está instalado."
        log_info "Use 'susa setup gcloud update' para atualizar."
        exit 0
    fi

    log_info "Iniciando instalação do Google Cloud SDK..."

    # Detect OS and architecture
    local os_arch=$(detect_os_and_arch)
    if [ $? -ne 0 ]; then
        return 1
    fi

    local os_name="${os_arch%%:*}"

    # Try Homebrew on macOS first
    if [ "$os_name" = "darwin" ]; then
        if install_gcloud_macos_brew; then
            local install_result=0
        else
            install_gcloud_tarball "$os_arch"
            local install_result=$?
        fi
    else
        # Linux: use tarball installation
        install_gcloud_tarball "$os_arch"
        local install_result=$?
    fi

    if [ $install_result -eq 0 ]; then
        # Verify installation
        # Need to reload PATH for current session
        export PATH="$HOME/.local/share/google-cloud-sdk/bin:$PATH"

        if check_installation; then
            local installed_version=$(get_current_version)
            log_success "Google Cloud SDK $installed_version instalado com sucesso!"
            register_or_update_software_in_lock "gcloud" "$installed_version"
            echo ""
            echo "Próximos passos:"
            log_output "  1. Reinicie o terminal ou execute: ${LIGHT_CYAN}source $(detect_shell_config)${NC}"
            log_output "  2. Autentique-se: ${LIGHT_CYAN}gcloud init${NC}"
            log_output "  3. Execute: ${LIGHT_CYAN}gcloud --version${NC}"
            log_output "  4. Use ${LIGHT_CYAN}susa setup gcloud --help${NC} para mais informações"
        else
            log_error "Google Cloud SDK foi instalado mas não está disponível no PATH"
            log_output "Tente reiniciar o terminal"
            return 1
        fi
    else
        return $install_result
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
