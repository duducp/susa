#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/shell.sh"
source "$UTILS_DIR/common.sh"

# Install Toolbox on Linux
install_toolbox_linux() {
    local version="$1"
    local os_arch="$2"

    local arch="${os_arch#*:}"
    local download_url=$(get_download_url "$os_arch")

    if [ -z "$download_url" ]; then
        log_error "Falha ao obter URL de download"
        return 1
    fi

    local temp_dir="/tmp/jetbrains-toolbox-$$"
    local install_dir=$(get_install_dir)
    local bin_dir="$LOCAL_BIN_DIR"

    # Create temp directory
    mkdir -p "$temp_dir"

    # Download
    log_info "Baixando JetBrains Toolbox..."
    if ! curl -L --progress-bar \
        --connect-timeout 30 \
        --max-time 300 \
        --retry 3 \
        --retry-delay 2 \
        "$download_url" -o "$temp_dir/toolbox.tar.gz"; then
        log_error "Falha ao baixar JetBrains Toolbox"
        rm -rf "$temp_dir"
        return 1
    fi

    # Extract
    log_info "Extraindo JetBrains Toolbox..."
    if ! tar -xzf "$temp_dir/toolbox.tar.gz" -C "$temp_dir" 2> /dev/null; then
        log_error "Falha ao extrair JetBrains Toolbox"
        rm -rf "$temp_dir"
        return 1
    fi

    # Find the extracted directory (it has a timestamp in the name)
    local extracted_dir=$(find "$temp_dir" -maxdepth 1 -type d -name "jetbrains-toolbox-*" | head -1)

    if [ -z "$extracted_dir" ]; then
        log_error "Diretório extraído não encontrado"
        rm -rf "$temp_dir"
        return 1
    fi

    # Create installation directory
    mkdir -p "$install_dir/bin"
    mkdir -p "$bin_dir"

    # Copy all contents to installation directory
    log_info "Copiando arquivos para $install_dir..."
    cp -r "$extracted_dir"/* "$install_dir/"

    # Find the binary in the installation directory
    local toolbox_binary=$(find "$install_dir" -type f -name "jetbrains-toolbox" | head -1)

    if [ -z "$toolbox_binary" ]; then
        log_error "Binário do JetBrains Toolbox não encontrado"
        rm -rf "$temp_dir"
        return 1
    fi

    log_debug "Binário encontrado: $toolbox_binary"
    chmod +x "$toolbox_binary"

    # Create symlink in ~/.local/bin
    ln -sf "$toolbox_binary" "$bin_dir/jetbrains-toolbox"
    log_debug "Link simbólico criado: $bin_dir/jetbrains-toolbox -> $toolbox_binary"

    # Save version
    echo "$version" > "$install_dir/.version"

    # Clean up
    rm -rf "$temp_dir"

    # Configure PATH if needed
    local shell_config=$(detect_shell_config)
    local local_bin="$LOCAL_BIN_DIR"
    if ! grep -q ".local/bin" "$shell_config" 2> /dev/null; then
        echo "" >> "$shell_config"
        echo "# Local binaries PATH" >> "$shell_config"
        echo "export PATH=\"$local_bin:\$PATH\"" >> "$shell_config"
        log_debug "PATH configurado em $shell_config"
    fi

    # Update current session PATH
    export PATH="$local_bin:$PATH"

    # Create desktop entry
    create_desktop_entry

    log_info "Iniciando JetBrains Toolbox..."
    nohup "$bin_dir/jetbrains-toolbox" > /dev/null 2>&1 &

    return 0
}

# Install Toolbox on macOS
install_toolbox_macos() {
    local version="$1"
    local os_arch="$2"

    local download_url=$(get_download_url "$os_arch")

    if [ -z "$download_url" ]; then
        log_error "Falha ao obter URL de download"
        return 1
    fi

    local temp_dir="/tmp/jetbrains-toolbox-$$"
    local install_dir=$(get_install_dir)

    # Create temp directory
    mkdir -p "$temp_dir"

    # Download
    log_info "Baixando JetBrains Toolbox..."
    if ! curl -L --progress-bar \
        --connect-timeout 30 \
        --max-time 300 \
        --retry 3 \
        --retry-delay 2 \
        "$download_url" -o "$temp_dir/toolbox.dmg"; then
        log_error "Falha ao baixar JetBrains Toolbox"
        rm -rf "$temp_dir"
        return 1
    fi

    # Mount DMG
    log_info "Montando imagem DMG..."
    local mount_point="/Volumes/JetBrains Toolbox"
    if ! hdiutil attach "$temp_dir/toolbox.dmg" -quiet; then
        log_error "Falha ao montar DMG"
        rm -rf "$temp_dir"
        return 1
    fi

    # Copy app to Applications
    log_info "Copiando para Applications..."
    if [ -d "$mount_point/JetBrains Toolbox.app" ]; then
        cp -R "$mount_point/JetBrains Toolbox.app" /Applications/
    else
        log_error "Aplicativo não encontrado no DMG"
        hdiutil detach "$mount_point" -quiet 2> /dev/null
        rm -rf "$temp_dir"
        return 1
    fi

    # Unmount DMG
    log_debug "Desmontando DMG..."
    hdiutil detach "$mount_point" -quiet 2> /dev/null || true

    # Save version
    mkdir -p "$install_dir"
    echo "$version" > "$install_dir/.version"

    # Clean up
    rm -rf "$temp_dir"

    log_info "Iniciando JetBrains Toolbox..."
    open -a "JetBrains Toolbox"

    return 0
}

# Main installation function
main() {
    if check_installation; then
        log_info "JetBrains Toolbox $(get_current_version) já está instalado."
        exit 0
    fi

    log_info "Iniciando instalação do JetBrains Toolbox..."

    # Get latest version
    local toolbox_version=$(get_latest_version)
    if [ $? -ne 0 ] || [ -z "$toolbox_version" ]; then
        return 1
    fi

    # Detect OS and architecture
    local os_arch=$(detect_os_and_arch)
    if [ $? -ne 0 ]; then
        return 1
    fi

    local os_name="${os_arch%:*}"

    log_info "Instalando JetBrains Toolbox $toolbox_version..."

    # Install based on OS
    case "$os_name" in
        linux)
            install_toolbox_linux "$toolbox_version" "$os_arch"
            ;;
        mac)
            install_toolbox_macos "$toolbox_version" "$os_arch"
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    local install_result=$?

    if [ $install_result -eq 0 ]; then
        log_success "JetBrains Toolbox $toolbox_version instalado com sucesso!"
        register_or_update_software_in_lock "jetbrains-toolbox" "$toolbox_version"
        log_debug "Instalação concluída"

        echo ""
        echo "Próximos passos:"
        log_output "  1. O JetBrains Toolbox foi iniciado automaticamente"
        log_output "  2. Faça login com sua conta JetBrains"
        log_output "  3. Instale as IDEs que desejar através do Toolbox"
        log_output "  4. Use ${LIGHT_CYAN}susa setup jetbrains-toolbox --help${NC} para mais informações"
    else
        log_error "Falha na instalação do JetBrains Toolbox"
        return $install_result
    fi
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
