#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

# Uninstall on macOS
uninstall_macos() {
    if homebrew_is_installed "$HOMEBREW_PACKAGE"; then
        homebrew_uninstall "$HOMEBREW_PACKAGE" "$SOFTWARE_NAME"
    else
        log_warning "$SOFTWARE_NAME não está instalado via Homebrew"
        return 1
    fi
}

# Uninstall on Linux
uninstall_linux() {
    local uninstalled=false

    # Tentar remover pacote .deb
    if is_linux_debian && dpkg -l | grep -q "cursor"; then
        log_info "Removendo pacote .deb..."
        if sudo dpkg -r cursor 2> /dev/null; then
            log_success "Pacote .deb removido"
            uninstalled=true
        fi
    fi

    # Tentar remover pacote .rpm
    if is_linux_redhat && rpm -qa | grep -q "cursor"; then
        log_info "Removendo pacote .rpm..."
        local pkg_manager=$(get_redhat_pkg_manager)
        if sudo "$pkg_manager" remove -y cursor 2> /dev/null; then
            log_success "Pacote .rpm removido"
            uninstalled=true
        fi
    fi

    # Remover instalação manual (tar.gz)
    local install_dir="$HOME/.local/cursor"
    local bin_link="$HOME/.local/bin/cursor"

    if [ -d "$install_dir" ] || [ -L "$bin_link" ]; then
        log_info "Removendo instalação manual..."

        if [ -d "$install_dir" ]; then
            rm -rf "$install_dir"
            log_debug "Diretório $install_dir removido"
        fi

        if [ -L "$bin_link" ] || [ -f "$bin_link" ]; then
            rm -f "$bin_link"
            log_debug "Link/executável $bin_link removido"
        fi

        uninstalled=true
    fi

    if [ "$uninstalled" = "true" ]; then
        log_success "Cursor removido com sucesso!"
        return 0
    else
        log_warning "Cursor não foi encontrado no sistema"
        return 1
    fi
}

# Main function
main() {
    local skip_confirm=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y | --yes)
                skip_confirm=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    log_info "Desinstalando $SOFTWARE_NAME..."

    if ! check_installation; then
        log_info "$SOFTWARE_NAME não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)
    log_debug "Versão a ser removida: $current_version"

    log_output ""
    if [ "$skip_confirm" = "false" ]; then
        log_output "${YELLOW}Deseja realmente desinstalar o $SOFTWARE_NAME $current_version? (s/N)${NC}"
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    if is_mac; then
        uninstall_macos
    else
        uninstall_linux
    fi

    local uninstall_result=$?

    if [ $uninstall_result -eq 0 ]; then
        if ! check_installation; then
            remove_software_in_lock "cursor"
            log_success "$SOFTWARE_NAME desinstalado com sucesso!"
        else
            log_error "Falha ao desinstalar $SOFTWARE_NAME completamente"
            return 1
        fi
    fi

    return $uninstall_result
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
