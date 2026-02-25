#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/homebrew.sh"
source "$LIB_DIR/sudo.sh"
source "$UTILS_DIR/common.sh"

# Show additional info in command help
show_complement_help() {
    log_output "${LIGHT_GREEN}O que faz:${NC}"
    log_output "  Remove o GitHub CLI do sistema"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup gh uninstall                 # Desinstala o GitHub CLI"
    log_output "  susa setup gh uninstall -v              # Desinstala com saída detalhada"
}

# Uninstall on macOS
uninstall_macos() {
    homebrew_uninstall "$HOMEBREW_FORMULA" "$SOFTWARE_NAME"
    return 0
}

# Uninstall on Linux
uninstall_linux() {
    log_info "Desinstalando $SOFTWARE_NAME..."

    local distro=$(get_distro_id)
    ensure_sudo

    case "$distro" in
        ubuntu | debian)
            sudo apt-get remove -y gh
            sudo apt-get autoremove -y
            ;;

        fedora | rhel | centos)
            sudo dnf remove -y gh
            ;;

        arch | manjaro)
            sudo pacman -Rs --noconfirm github-cli
            ;;

        opensuse*)
            sudo zypper remove -y gh
            ;;

        *)
            log_error "Distribuição não suportada: $distro"
            return 1
            ;;
    esac

    return 0
}

# Main function
main() {
    if ! check_installation; then
        log_warning "$SOFTWARE_NAME não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)
    log_info "Versão instalada: $current_version"

    log_info "Desinstalando $SOFTWARE_NAME..."

    if is_mac; then
        if ! uninstall_macos; then
            log_error "Falha ao desinstalar $SOFTWARE_NAME no macOS"
            return 1
        fi
    elif is_linux; then
        if ! uninstall_linux; then
            log_error "Falha ao desinstalar $SOFTWARE_NAME no Linux"
            return 1
        fi
    else
        log_error "Sistema operacional não suportado"
        return 1
    fi

    # Verify uninstallation
    if check_installation; then
        log_error "Desinstalação falhou - comando $BIN_NAME ainda está disponível"
        return 1
    fi

    # Remove from lock file
    remove_software_in_lock "gh"

    log_success "✓ $SOFTWARE_NAME desinstalado com sucesso!"
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
