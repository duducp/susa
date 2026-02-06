#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/../utils"
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/shell.sh"
source "$UTILS_DIR/common.sh"

# Detect operating system and architecture
detect_os_and_arch() {
    local os_arch
    os_arch=$(github_detect_os_arch "darwin-macos")
    [ $? -ne 0 ] && return 1

    local os_name="${os_arch%:*}"
    local arch="${os_arch#*:}"

    # ASDF usa amd64 em vez de x64
    [ "$arch" = "x64" ] && arch="amd64"

    echo "${os_name}:${arch}"
}

# Check if ASDF is already configured in shell
is_asdf_configured() {
    local shell_config="$1"
    grep -q "ASDF_DATA_DIR" "$shell_config" 2> /dev/null
}

# Add ASDF configuration to shell
add_asdf_to_shell() {
    local asdf_dir="$1"
    local shell_config="$2"

    echo "" >> "$shell_config"
    echo "# ASDF Version Manager" >> "$shell_config"
    echo "export PATH=\"$LOCAL_BIN_DIR:\$PATH\"" >> "$shell_config"
    echo "export ASDF_DATA_DIR=\"$asdf_dir\"" >> "$shell_config"
    echo "export PATH=\"\$ASDF_DATA_DIR/bin:\$ASDF_DATA_DIR/shims:\$PATH\"" >> "$shell_config"
}

# Configure shell to use ASDF
configure_shell() {
    local asdf_dir="$1"
    local shell_config=$(detect_shell_config)

    log_debug "Arquivo de configuração: $shell_config"

    if is_asdf_configured "$shell_config"; then
        log_debug "ASDF já configurado em $shell_config"
        return 0
    fi

    log_debug "Configurando $shell_config..."
    add_asdf_to_shell "$asdf_dir" "$shell_config"
    log_debug "Configuração adicionada"
}

# Download ASDF release with checksum verification
download_asdf_release() {
    local download_url="$1"
    local checksum_url="$2"
    local output_file="/tmp/asdf.tar.gz"

    if github_download_and_verify \
        "$download_url" \
        "$checksum_url" \
        "$output_file" \
        "md5" \
        "ASDF"; then
        echo "$output_file"
        return 0
    else
        return 1
    fi
}

# Extract and setup ASDF binary
extract_and_setup_binary() {
    local tar_file="$1"
    local asdf_dir="$2"

    # Extract tarball
    local extracted_dir
    extracted_dir=$(github_extract_tarball "$tar_file" "/tmp/asdf-extract-$$")
    if [ $? -ne 0 ]; then
        rm -f "$tar_file"
        return 1
    fi

    rm -f "$tar_file"

    # Create directory structure
    mkdir -p "$asdf_dir/bin"

    # Find and move binary
    local asdf_binary=$(find "$extracted_dir" -type f -name "asdf" | head -1)

    if [ -z "$asdf_binary" ]; then
        log_error "Binário do ASDF não encontrado no arquivo"
        rm -rf "$extracted_dir"
        return 1
    fi

    log_debug "Binário encontrado: $asdf_binary"
    mv "$asdf_binary" "$asdf_dir/bin/asdf"
    chmod +x "$asdf_dir/bin/asdf"

    # Cleanup
    rm -rf "$extracted_dir"

    log_debug "Binário instalado em $asdf_dir/bin/asdf"
}

# Configure environment variables for current session
setup_asdf_environment() {
    local asdf_dir="$1"

    export PATH="$LOCAL_BIN_DIR:$PATH"
    export ASDF_DATA_DIR="$asdf_dir"
    export PATH="$ASDF_DATA_DIR/bin:$ASDF_DATA_DIR/shims:$PATH"

    log_debug "Ambiente configurado para sessão atual"
}

# Main installation function
install_asdf_release() {
    local asdf_dir="$ASDF_INSTALL_DIR"

    local asdf_version=$(get_latest_version)
    if [ $? -ne 0 ] || [ -z "$asdf_version" ]; then
        return 1
    fi

    # Detect OS and architecture
    local os_arch=$(detect_os_and_arch)
    [ $? -ne 0 ] && return 1

    local os_name="${os_arch%:*}"
    local arch="${os_arch#*:}"

    log_info "Instalando ASDF $asdf_version..."

    # Build release URLs
    local download_url
    download_url=$(github_build_download_url \
        "$ASDF_REPO" \
        "$asdf_version" \
        "$os_name" \
        "$arch" \
        "asdf-v{version}-{os}-{arch}.tar.gz")

    local checksum_url
    checksum_url=$(github_build_download_url \
        "$ASDF_REPO" \
        "$asdf_version" \
        "$os_name" \
        "$arch" \
        "asdf-v{version}-{os}-{arch}.tar.gz.md5")

    # Download and verify release
    local tar_file=$(download_asdf_release "$download_url" "$checksum_url")
    [ $? -ne 0 ] && return 1

    # Extract and setup binary
    extract_and_setup_binary "$tar_file" "$asdf_dir"
    [ $? -ne 0 ] && return 1

    # Configure shell
    configure_shell "$asdf_dir"

    # Configure environment for current session
    setup_asdf_environment "$asdf_dir"
}

main() {
    if check_installation; then
        log_info "ASDF $(get_current_version) já está instalado."
        exit 0
    fi

    install_asdf_release

    # Verify installation
    if check_installation; then
        local version=$(get_current_version)
        log_success "ASDF instalado com sucesso!"
        register_or_update_software_in_lock "asdf" "$version"
    else
        log_error "ASDF foi instalado mas não está disponível no PATH"
        local shell_config=$(detect_shell_config)
        log_info "Tente reiniciar o terminal ou executar: source $shell_config"
        return 1
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
