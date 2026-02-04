#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"
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

main() {
    local asdf_dir="$ASDF_INSTALL_DIR"

    # Check if ASDF is installed
    if [ ! -d "$asdf_dir" ] || [ ! -f "$asdf_dir/bin/asdf" ]; then
        log_error "ASDF não está instalado. Use 'susa setup asdf install' para instalar."
        return 1
    fi

    local current_version=$(get_current_version)

    # Get latest version
    local asdf_version=$(get_latest_version)
    if [ $? -ne 0 ] || [ -z "$asdf_version" ]; then
        return 1
    fi

    if [ "$current_version" = "$asdf_version" ]; then
        log_info "Você já possui a versão mais recente instalada ($current_version)"
        return 0
    fi

    log_info "Atualizando ASDF de $current_version para $asdf_version..."

    # Detect OS and architecture
    local os_arch=$(detect_os_and_arch)
    [ $? -ne 0 ] && return 1

    local os_name="${os_arch%:*}"
    local arch="${os_arch#*:}"

    # Backup plugins and tool versions
    local backup_dir="/tmp/asdf-backup-$$"
    mkdir -p "$backup_dir"

    if [ -d "$asdf_dir/plugins" ]; then
        cp -r "$asdf_dir/plugins" "$backup_dir/" 2> /dev/null || true
    fi

    if [ -f "$HOME/.tool-versions" ]; then
        cp "$HOME/.tool-versions" "$backup_dir/" 2> /dev/null || true
    fi

    # Remove old installation (plugins e versões de ferramentas serão preservados)
    rm -rf "$asdf_dir"

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
    if [ $? -ne 0 ]; then
        # Restore backup on failure
        if [ -d "$backup_dir/plugins" ]; then
            mkdir -p "$asdf_dir"
            cp -r "$backup_dir/plugins" "$asdf_dir/" 2> /dev/null || true
        fi
        rm -rf "$backup_dir"
        return 1
    fi

    # Extract and setup binary
    extract_and_setup_binary "$tar_file" "$asdf_dir"
    if [ $? -ne 0 ]; then
        rm -rf "$backup_dir"
        return 1
    fi

    # Restore plugins
    if [ -d "$backup_dir/plugins" ]; then
        cp -r "$backup_dir/plugins" "$asdf_dir/" 2> /dev/null || true
    fi

    if [ -f "$backup_dir/.tool-versions" ]; then
        cp "$backup_dir/.tool-versions" "$HOME/" 2> /dev/null || true
    fi

    # Cleanup backup
    rm -rf "$backup_dir"

    # Configure environment for current session
    setup_asdf_environment "$asdf_dir"

    # Verify update
    if check_installation; then
        local new_version=$(get_current_version)
        log_success "ASDF atualizado para versão $new_version!"
        register_or_update_software_in_lock "asdf" "$new_version"
    else
        log_error "Falha na atualização do ASDF"
        return 1
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
