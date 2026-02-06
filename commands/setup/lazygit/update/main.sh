#!/usr/bin/env zsh

UTILS_DIR="$(dirname "$0")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/homebrew.sh"
source "$LIB_DIR/github.sh"
source "$UTILS_DIR/common.sh"

# Show additional info in command help
show_complement_help() {
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Atualiza o Lazygit para a versão mais recente disponível"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup lazygit update               # Atualiza o Lazygit"
    log_output "  susa setup lazygit update -v            # Atualiza com saída detalhada"
}

# Update on macOS
update_macos() {
    homebrew_upgrade "$HOMEBREW_FORMULA" "$SOFTWARE_NAME"
    return $?
}

# Update on Linux (reinstall from GitHub)
update_linux() {
    log_info "Atualizando $SOFTWARE_NAME..."

    # Remove old version
    local install_dir="$HOME/.local/bin"
    if [ -f "$install_dir/$BIN_NAME" ]; then
        rm -f "$install_dir/$BIN_NAME"
    fi

    # Reinstall (same logic as install)
    local os_arch=$(github_detect_os_arch "standard")
    local arch="${os_arch#*:}"

    local release_arch=""
    case "$arch" in
        x64) release_arch="x86_64" ;;
        arm64) release_arch="arm64" ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    local latest_version=$(github_get_latest_version "$GITHUB_REPO" "true")
    if [ -z "$latest_version" ]; then
        log_error "Não foi possível obter a versão mais recente"
        return 1
    fi

    log_info "Versão mais recente: v$latest_version"

    local filename="lazygit_${latest_version}_Linux_${release_arch}.tar.gz"
    local download_url="https://github.com/${GITHUB_REPO}/releases/download/v${latest_version}/${filename}"

    local temp_dir=$(mktemp -d)
    local archive_path="$temp_dir/$filename"

    if ! github_download_release "$download_url" "$archive_path" "$SOFTWARE_NAME"; then
        rm -rf "$temp_dir"
        return 1
    fi

    tar -xzf "$archive_path" -C "$temp_dir"

    mkdir -p "$install_dir"

    if [ -f "$temp_dir/$BIN_NAME" ]; then
        mv "$temp_dir/$BIN_NAME" "$install_dir/"
        chmod +x "$install_dir/$BIN_NAME"
    else
        log_error "Binário não encontrado no arquivo"
        rm -rf "$temp_dir"
        return 1
    fi

    rm -rf "$temp_dir"

    if command -v "$BIN_NAME" &> /dev/null; then
        export INSTALLED_VERSION="$latest_version"
        return 0
    else
        log_error "Falha ao atualizar"
        return 1
    fi
}

# Main function
main() {
    if ! check_installation; then
        log_error "$SOFTWARE_NAME não está instalado"
        log_info "Use ${LIGHT_CYAN}susa setup lazygit install${NC} para instalar"
        return 1
    fi

    local current_version=$(get_current_version)
    local latest_version=$(get_latest_version)

    log_info "Versão atual: $current_version"
    log_info "Versão mais recente: $latest_version"

    if [ "$current_version" = "$latest_version" ]; then
        log_success "$SOFTWARE_NAME já está na versão mais recente"
        return 0
    fi

    log_info "Atualizando de $current_version para $latest_version..."

    local update_result=1
    if is_mac; then
        update_macos
        update_result=$?
    elif is_linux; then
        update_linux
        update_result=$?
    else
        log_error "Sistema operacional não suportado"
        return 1
    fi

    if [ $update_result -eq 0 ]; then
        local installed_version=$(get_current_version)
        register_or_update_software_in_lock "lazygit" "$installed_version"
        log_success "✓ $SOFTWARE_NAME atualizado com sucesso para versão $installed_version!"
    else
        log_error "✗ Falha ao atualizar $SOFTWARE_NAME"
        return 1
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
