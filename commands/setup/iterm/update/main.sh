#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

main() {
    # Verify it's macOS
    if [[ "$(uname -s)" != "Darwin" ]]; then
        log_error "iTerm2 só está disponível para macOS"
        exit 1
    fi

    # Check if Homebrew is installed
    if ! homebrew_is_available; then
        log_error "Homebrew não está instalado"
        return 1
    fi

    # Check if iTerm2 is installed
    if ! homebrew_is_installed "$ITERM_HOMEBREW_CASK"; then
        log_error "iTerm2 não está instalado"
        echo ""
        log_output "${YELLOW}Para instalar, execute:${NC}"
        echo "  susa setup iterm install"
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"

    # Get latest version
    local latest_version=$(get_latest_version)
    if [ $? -ne 0 ] || [ -z "$latest_version" ]; then
        log_warning "Não foi possível verificar a última versão. Continuando com atualização via Homebrew..."
    elif [ "$current_version" = "$latest_version" ]; then
        log_info "Você já possui a versão mais recente instalada ($current_version)"
        return 0
    else
        log_info "Atualizando de $current_version para $latest_version..."
    fi

    # Update Homebrew
    log_info "Atualizando Homebrew..."
    homebrew_update_metadata

    # Upgrade iTerm2
    log_info "Atualizando iTerm2 para a versão mais recente..."
    if ! homebrew_update "$ITERM_HOMEBREW_CASK" "iTerm2"; then
        log_error "Falha ao atualizar iTerm2"
        return 1
    fi

    local new_version=$(get_current_version)
    log_success "iTerm2 atualizado de $current_version para $new_version"
    register_or_update_software_in_lock "iterm" "$new_version"
    log_debug "Atualização concluída com sucesso"
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
