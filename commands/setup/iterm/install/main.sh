#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

ITERM_HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

main() {
    # Verify it's macOS
    if [[ "$(uname -s)" != "Darwin" ]]; then
        log_error "iTerm2 só está disponível para macOS"
        exit 1
    fi

    # Check if Homebrew is installed
    if ! homebrew_is_available; then
        log_error "Homebrew não está instalado"
        echo ""
        log_output "${YELLOW}Para instalar o Homebrew, execute:${NC}"
        log_output "  /bin/bash -c \"\$(curl -fsSL $ITERM_HOMEBREW_INSTALL_URL)\""
        return 1
    fi

    if check_installation; then
        log_info "iTerm2 $(get_current_version) já está instalado."
        exit 0
    fi

    log_info "Iniciando instalação do iTerm2..."

    # Update Homebrew
    log_info "Atualizando Homebrew..."
    homebrew_update_metadata

    # Install or reinstall iTerm2
    log_info "Instalando iTerm2 via Homebrew..."
    if ! homebrew_install "$ITERM_HOMEBREW_CASK" "iTerm2"; then
        log_error "Falha ao instalar iTerm2"
        return 1
    fi

    # Verify installation
    if check_installation; then
        local version=$(get_current_version)
        log_success "iTerm2 $version instalado com sucesso!"
        register_or_update_software_in_lock "iterm" "$version"
        log_debug "Localização: /Applications/iTerm.app"
        return 0
    else
        log_error "Falha ao verificar instalação do iTerm2"
        return 1
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
