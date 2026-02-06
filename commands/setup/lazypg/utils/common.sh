#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# Source required libraries
source "$LIB_DIR/github.sh"
source "$LIB_DIR/homebrew.sh"

# Constants
readonly LAZYPG_NAME="lazypg"
readonly LAZYPG_REPO="rebelice/lazypg"
readonly LAZYPG_HOMEBREW_TAP="rebelice/tap"
readonly LAZYPG_HOMEBREW_FORMULA="lazypg"
readonly LAZYPG_BIN_NAME="lazypg"

# Check if lazypg is installed
check_installation() {
    if is_mac; then
        homebrew_is_installed "$LAZYPG_HOMEBREW_FORMULA"
    else
        command -v "$LAZYPG_BIN_NAME" &> /dev/null
    fi
}

# Get current installed version
get_current_version() {
    if check_installation; then
        if is_mac; then
            homebrew_get_installed_version "$LAZYPG_HOMEBREW_FORMULA"
        else
            local version=$(get_installed_version "$LAZYPG_NAME" 2> /dev/null || echo "")
            echo "$version"
        fi
    fi
}

# Get latest version
get_latest_version() {
    if is_mac; then
        homebrew_get_latest_version "$LAZYPG_HOMEBREW_FORMULA"
    else
        local latest=$(github_get_latest_version "$LAZYPG_REPO" 2> /dev/null || echo "")
        if [ -n "$latest" ]; then
            echo "${latest#v}"
        fi
    fi
}
# Install or update lazypg on Linux (shared logic)
# This function downloads and installs the latest version from GitHub releases
# Returns: 0 on success, 1 on failure
# Exports: INSTALLED_LAZYPG_VERSION with the installed version
install_or_update_lazypg_linux() {
    log_info "Obtendo LazyPG via GitHub Releases..."

    # Detect architecture
    local os_arch=$(github_detect_os_arch "standard")
    local arch="${os_arch#*:}"

    # Map architecture to lazypg release naming
    local release_arch=""
    case "$arch" in
        x64) release_arch="amd64" ;;
        arm64) release_arch="arm64" ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    # Get latest version
    log_debug "Obtendo versão mais recente do LazyPG..."
    local latest_version=$(github_get_latest_version "$LAZYPG_REPO" "true")

    if [ -z "$latest_version" ]; then
        log_error "Não foi possível obter a versão mais recente do LazyPG"
        return 1
    fi

    log_info "Versão mais recente: v$latest_version"

    # Export version for use in calling functions
    export INSTALLED_LAZYPG_VERSION="$latest_version"

    # Build download URL
    local version_number="${latest_version#v}"
    local download_url="https://github.com/${LAZYPG_REPO}/releases/download/v${version_number}/lazypg_${version_number}_linux_${release_arch}.tar.gz"

    log_debug "URL de download: $download_url"

    # Create temporary directory
    local temp_dir=$(mktemp -d)
    local download_file="$temp_dir/lazypg.tar.gz"
    local extract_dir="$temp_dir/extracted"

    # Download release
    if ! github_download_release "$download_url" "$download_file" "LazyPG"; then
        log_error "Falha ao baixar LazyPG"
        rm -rf "$temp_dir"
        return 1
    fi

    # Extract archive
    log_info "Extraindo arquivos..."
    mkdir -p "$extract_dir"
    if ! tar -xzf "$download_file" -C "$extract_dir"; then
        log_error "Falha ao extrair arquivo"
        rm -rf "$temp_dir"
        return 1
    fi

    # Find binary in extracted files
    local binary_path=$(find "$extract_dir" -name "$LAZYPG_BIN_NAME" -type f | head -1)
    if [ -z "$binary_path" ]; then
        log_error "Binário do LazyPG não encontrado no arquivo baixado"
        rm -rf "$temp_dir"
        return 1
    fi

    # Install binary to /usr/local/bin
    local install_dir="/usr/local/bin"
    log_info "Instalando binário em $install_dir..."

    if [ -w "$install_dir" ]; then
        cp "$binary_path" "$install_dir/$LAZYPG_BIN_NAME"
        chmod +x "$install_dir/$LAZYPG_BIN_NAME"
    else
        sudo cp "$binary_path" "$install_dir/$LAZYPG_BIN_NAME"
        sudo chmod +x "$install_dir/$LAZYPG_BIN_NAME"
    fi

    if [ ! -x "$install_dir/$LAZYPG_BIN_NAME" ]; then
        log_error "Falha ao instalar binário"
        rm -rf "$temp_dir"
        return 1
    fi

    rm -rf "$temp_dir"
    return 0
}
