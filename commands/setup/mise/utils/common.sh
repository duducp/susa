#!/usr/bin/env zsh
# Mise Common Utilities
# Shared functions used across install, update and uninstall

# Constants
MISE_NAME="Mise"
MISE_REPO="jdx/mise"
MISE_BIN_NAME="mise"
MISE_CACHE_DIR="$HOME/.cache/mise"
MISE_DATA_DIR="$HOME/.local/share/mise"
MISE_CONFIG_DIR="$HOME/.config/mise"
LOCAL_BIN_DIR="$HOME/.local/bin"
MISE_CONFIG_COMMENT="# Mise (polyglot version manager)"
MISE_ACTIVATE_PATTERN="mise activate"
MISE_TAR_PATTERN="mise-v{version}-{os}-{arch}.tar.gz"

# Get latest version
get_latest_version() {
    github_get_latest_version "$MISE_REPO"
}

# Get installed Mise version
get_current_version() {
    if check_installation; then
        $MISE_BIN_NAME --version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Check if Mise is installed
check_installation() {
    command -v $MISE_BIN_NAME &> /dev/null
}

# Show additional Mise-specific information
show_additional_info() {
    if ! check_installation; then
        return
    fi

    # List installed tools
    local tools=$(mise list 2> /dev/null | grep -v "^$" | wc -l | xargs)
    if [ "$tools" != "0" ]; then
        log_output "  ${CYAN}Tools:${NC} $tools instalados"

        # Show tools with versions
        local tool_list=$(mise list 2> /dev/null | awk '{print $1, $2}' | sort -u)
        if [ -n "$tool_list" ]; then
            log_output "  ${CYAN}Runtimes:${NC}"
            echo "$tool_list" | head -5 | while read -r tool version; do
                [ -n "$tool" ] && log_output "    • $tool@$version"
            done
            local remaining=$((tools - 5))
            if [ $remaining -gt 0 ]; then
                log_output "    ... e mais $remaining"
            fi
        fi
    else
        log_output "  ${CYAN}Tools:${NC} nenhum instalado"
    fi
}

# Check if Mise is already configured in shell
is_mise_configured() {
    local shell_config="$1"
    grep -q "$MISE_ACTIVATE_PATTERN" "$shell_config" 2> /dev/null
}

# Add Mise configuration to shell
add_mise_to_shell() {
    local shell_config="$1"
    local shell_type="bash"

    if [[ "$shell_config" == *"zshrc"* ]]; then
        shell_type="zsh"
    fi

    echo "" >> "$shell_config"
    echo "$MISE_CONFIG_COMMENT" >> "$shell_config"
    echo "export PATH=\"$LOCAL_BIN_DIR:\$PATH\"" >> "$shell_config"
    echo "eval \"\$($MISE_BIN_NAME activate $shell_type)\"" >> "$shell_config"
}

# Configure shell to use Mise
configure_shell() {
    local shell_config=$(detect_shell_config)

    log_debug "Arquivo de configuração: $shell_config"

    if is_mise_configured "$shell_config"; then
        log_debug "Mise já configurado em $shell_config"
        return 0
    fi

    log_debug "Configurando $shell_config..."
    add_mise_to_shell "$shell_config"
    log_debug "Configuração adicionada"
}

# Download Mise release
download_mise() {
    local version="$1"
    local os_name="$2"
    local arch="$3"
    local output_file="/tmp/${MISE_BIN_NAME}-${version}.tar.gz"
    local download_url=$(github_build_download_url "$MISE_REPO" "$version" "$os_name" "$arch" "$MISE_TAR_PATTERN")

    log_info "Baixando Mise..."
    log_debug "URL: $download_url"

    if ! github_download_release "$download_url" "$output_file" "Mise"; then
        log_error "Falha ao baixar Mise"
        return 1
    fi

    echo "$output_file"
}

# Extract and setup Mise binary
extract_and_setup_binary() {
    local tar_file="$1"
    local bin_dir="$2"

    log_info "Extraindo Mise..."

    # Create bin directory
    mkdir -p "$bin_dir"

    # Extract binary
    local temp_dir="/tmp/mise-extract-$$"
    mkdir -p "$temp_dir"

    tar -xzf "$tar_file" -C "$temp_dir" 2>&1 | while read -r line; do log_debug "tar: $line"; done || true
    local exit_code=$?
    rm -f "$tar_file"

    if [ $exit_code -ne 0 ]; then
        log_error "Falha ao extrair Mise"
        rm -rf "$temp_dir"
        return 1
    fi

    # Find and move binary
    local mise_binary=$(find "$temp_dir" -type f -name "$MISE_BIN_NAME" | head -1)
    if [ -z "$mise_binary" ]; then
        log_error "Binário do Mise não encontrado no arquivo"
        rm -rf "$temp_dir"
        return 1
    fi

    log_debug "Binário encontrado: $mise_binary"
    local mise_bin="$LOCAL_BIN_DIR/$MISE_BIN_NAME"
    mv "$mise_binary" "$mise_bin"
    chmod +x "$mise_bin"
    rm -rf "$temp_dir"
    log_debug "Binário instalado em $mise_bin"
}

# Setup Mise environment for current session
setup_mise_environment() {
    local bin_dir="$1"

    export PATH="$bin_dir:$PATH"
    log_debug "Ambiente configurado para sessão atual"
    log_debug "PATH atualizado com: $bin_dir"
}

# Configure legacy version file support
configure_legacy_support() {
    local enable_legacy="$1"

    if [ "$enable_legacy" = "true" ]; then
        log_debug "Habilitando suporte a arquivos legados (.tool-versions, .node-version, etc)"
        if $MISE_BIN_NAME settings set legacy_version_file true 2>&1 | while read -r line; do log_debug "mise: $line"; done; then
            log_info "Suporte ao legado habilitado"
        else
            log_warning "Não foi possível habilitar o suporte ao legado automaticamente"
            log_info "Execute manualmente: mise settings set legacy_version_file true"
        fi
    else
        log_debug "Suporte a arquivos legados não habilitado"
        $MISE_BIN_NAME settings set legacy_version_file false 2>&1 | while read -r line; do log_debug "mise: $line"; done || true
    fi
}
