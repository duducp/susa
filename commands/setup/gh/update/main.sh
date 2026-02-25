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
    log_output "  Atualiza o GitHub CLI para a versão mais recente disponível"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup gh update                    # Atualiza o GitHub CLI"
    log_output "  susa setup gh update -v                 # Atualiza com saída detalhada"
}

# Update on macOS
update_macos() {
    homebrew_upgrade "$HOMEBREW_FORMULA" "$SOFTWARE_NAME"
    return 0
}

# Update on Linux
update_linux() {
    log_info "Atualizando $SOFTWARE_NAME..."

    local distro=$(get_distro_id)
    ensure_sudo

    case "$distro" in
        ubuntu | debian)
            sudo apt-get update
            sudo apt-get upgrade -y gh
            ;;

        fedora | rhel | centos)
            sudo dnf upgrade -y gh
            ;;

        arch | manjaro)
            sudo pacman -Sy --noconfirm github-cli
            ;;

        opensuse*)
            sudo zypper update -y gh
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
        log_error "$SOFTWARE_NAME não está instalado"
        log_output "Para instalar, use: ${LIGHT_CYAN}susa setup gh install${NC}"
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"

    local latest_version=$(get_latest_version)
    if [ -n "$latest_version" ] && [ "$latest_version" != "N/A" ]; then
        log_info "Versão mais recente: $latest_version"

        if [ "$current_version" = "$latest_version" ]; then
            log_success "✓ $SOFTWARE_NAME já está na versão mais recente"
            return 0
        fi
    fi

    log_info "Atualizando $SOFTWARE_NAME..."

    if is_mac; then
        if ! update_macos; then
            log_error "Falha ao atualizar $SOFTWARE_NAME no macOS"
            return 1
        fi
    elif is_linux; then
        if ! update_linux; then
            log_error "Falha ao atualizar $SOFTWARE_NAME no Linux"
            return 1
        fi
    else
        log_error "Sistema operacional não suportado"
        return 1
    fi

    # Get new version
    local new_version=$(get_current_version)

    # Update lock file
    register_or_update_software_in_lock "gh" "$new_version"

    log_success "✓ $SOFTWARE_NAME atualizado com sucesso!"
    log_output "Versão: $current_version → $new_version"
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
