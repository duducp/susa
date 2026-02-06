#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# Source required libraries
source "$LIB_DIR/github.sh"
source "$LIB_DIR/shell.sh"

# Constants
UV_NAME="UV"
UV_REPO="astral-sh/uv"
UV_BIN_NAME="uv"
UV_BIN_NAME_UVX="uvx"
GITHUB_BASE_URL="https://github.com"
LOCAL_BIN_DIR="$HOME/.local/bin"
TEMP_DIR="/tmp"
UV_DATA_DIR="$HOME/.local/share/uv"
UV_CACHE_DIR="$HOME/.cache/uv"

# ============================================================================
# MANDATORY FUNCTIONS (Required by SUSA standards)
# ============================================================================

# Check if UV is installed
check_installation() {
    command -v uv &> /dev/null
}

# Get installed UV version
get_current_version() {
    if check_installation; then
        $UV_BIN_NAME --version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Get latest UV version from GitHub
get_latest_version() {
    github_get_latest_version "$UV_REPO"
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Detect OS and architecture for UV (uses specific naming)
detect_uv_platform() {
    local os_name=$(uname -s)
    local arch=$(uname -m)

    # Convert OS name
    case "$os_name" in
        Linux) os_name="unknown-linux-gnu" ;;
        Darwin) os_name="apple-darwin" ;;
        *)
            log_error "Sistema operacional não suportado: $os_name" >&2
            return 1
            ;;
    esac

    # Convert architecture
    case "$arch" in
        x86_64) arch="x86_64" ;;
        aarch64 | arm64) arch="aarch64" ;;
        armv7l) arch="armv7" ;;
        *)
            log_error "Arquitetura não suportada: $arch" >&2
            return 1
            ;;
    esac

    echo "${arch}-${os_name}"
}

# Configure shell to use UV
configure_shell() {
    local bin_dir="$1"
    local shell_config=$(detect_shell_config)

    log_debug "Arquivo de configuração: $shell_config"

    # Check if .local/bin is already in PATH
    if grep -q ".local/bin" "$shell_config" 2> /dev/null; then
        log_debug ".local/bin já configurado em $shell_config"
        return 0
    fi

    log_debug "Configurando $shell_config..."

    echo "" >> "$shell_config"
    echo "# Local binaries PATH" >> "$shell_config"
    echo "export PATH=\"$LOCAL_BIN_DIR:\$PATH\"" >> "$shell_config"

    log_debug "Configuração adicionada ao shell"
}

# Setup UV environment for current session
setup_uv_environment() {
    local bin_dir="$1"

    export PATH="$bin_dir:$PATH"

    log_debug "Ambiente configurado para sessão atual"
    log_debug "PATH atualizado com: $bin_dir"
}

# Download and extract UV
download_and_extract_uv() {
    local uv_version="$1"
    local platform="$2"
    local bin_dir="$3"

    # Build download URL
    local filename="uv-${platform}.tar.gz"
    local download_url="${GITHUB_BASE_URL}/astral-sh/uv/releases/download/${uv_version}/${filename}"
    local checksum_filename="${filename}.sha256"
    local output_file="${TEMP_DIR}/${filename}"

    log_info "Baixando e verificando UV ${uv_version}..."
    log_debug "Plataforma: $platform"
    log_debug "URL: $download_url"

    # Download and verify with checksum
    if ! github_download_and_verify "astral-sh/uv" "$uv_version" "$download_url" "$output_file" "$checksum_filename" "sha256"; then
        log_error "Falha ao baixar ou verificar UV"
        return 1
    fi

    # Extract binary
    log_info "Extraindo UV..."
    local temp_dir="${TEMP_DIR}/uv-extract-$$"
    mkdir -p "$temp_dir"

    if ! tar -xzf "$output_file" -C "$temp_dir" 2> /dev/null; then
        log_error "Falha ao extrair UV"
        rm -rf "$temp_dir" "$output_file"
        return 1
    fi
    rm -f "$output_file"

    # Find and install binaries
    local uv_binary=$(find "$temp_dir" -type f -name "uv" -o -name "uvx" | grep -E "/uv$" | head -1)
    local uvx_binary=$(find "$temp_dir" -type f -name "uvx" | head -1)

    if [ -z "$uv_binary" ]; then
        log_error "Binário do UV não encontrado no arquivo"
        rm -rf "$temp_dir"
        return 1
    fi

    log_debug "Binário UV encontrado: $uv_binary"
    mv "$uv_binary" "$bin_dir/uv"
    chmod +x "$bin_dir/uv"

    if [ -n "$uvx_binary" ]; then
        log_debug "Binário UVX encontrado: $uvx_binary"
        mv "$uvx_binary" "$bin_dir/uvx"
        chmod +x "$bin_dir/uvx"
    fi

    rm -rf "$temp_dir"
    log_debug "Binários instalados em $bin_dir"

    return 0
}

# Remove UV binaries
remove_uv_binaries() {
    local bin_dir="$LOCAL_BIN_DIR"

    log_info "Removendo binários do UV..."

    if [ -f "$bin_dir/uv" ]; then
        rm -f "$bin_dir/uv"
        log_debug "Removido: $bin_dir/uv"
    fi

    if [ -f "$bin_dir/uvx" ]; then
        rm -f "$bin_dir/uvx"
        log_debug "Removido: $bin_dir/uvx"
    fi
}

# Remove UV data (installed tools)
remove_uv_data() {
    local skip_confirm="${1:-false}"

    # Ask about removing installed tools (ruff, black, mypy, etc)
    if [ "$skip_confirm" = false ]; then
        echo ""
        log_output "${YELLOW}Deseja remover também as ferramentas instaladas com UV (ruff, black, mypy, etc)? (s/N)${NC}"
        read -r tools_response

        if [[ "$tools_response" =~ ^[sSyY]$ ]]; then
            local uv_data_dir="${UV_DATA_DIR}"
            if [ -d "$uv_data_dir" ]; then
                rm -rf "$uv_data_dir"
                log_debug "Ferramentas removidas: $uv_data_dir"
            fi
            log_success "Ferramentas instaladas removidas"
        else
            log_info "Ferramentas mantidas em ${UV_DATA_DIR}"
        fi
    else
        # Auto-remove when --yes is used
        local uv_data_dir="${UV_DATA_DIR}"
        if [ -d "$uv_data_dir" ]; then
            rm -rf "$uv_data_dir"
            log_debug "Ferramentas removidas: $uv_data_dir"
        fi
        log_info "Ferramentas instaladas removidas automaticamente"
    fi
}

# Remove UV cache
remove_uv_cache() {
    local skip_confirm="${1:-false}"

    # Ask about cache removal
    if [ "$skip_confirm" = false ]; then
        echo ""
        log_output "${YELLOW}Deseja remover também o cache do UV? (s/N)${NC}"
        read -r cache_response

        if [[ "$cache_response" =~ ^[sSyY]$ ]]; then
            local cache_dir="${UV_CACHE_DIR}"
            if [ -d "$cache_dir" ]; then
                rm -rf "$cache_dir" 2> /dev/null || true
            fi
            log_success "Cache removido"
        else
            log_info "Cache mantido em ${UV_CACHE_DIR}"
        fi
    else
        # Auto-remove when --yes is used
        local cache_dir="${UV_CACHE_DIR}"
        if [ -d "$cache_dir" ]; then
            rm -rf "$cache_dir" 2> /dev/null || true
            log_debug "Cache removido automaticamente"
        fi
    fi
}
