#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/../utils"
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

SKIP_CONFIRM=false

show_help() {
    show_description
    log_output ""
    show_usage "[options]"
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -y, --yes         Pula confirmação"
    log_output "  -h, --help        Mostra esta mensagem"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup iterm uninstall        # Desinstala com confirmação"
    log_output "  susa setup iterm uninstall -y     # Desinstala sem confirmação"
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y | --yes)
                SKIP_CONFIRM=true
                shift
                ;;
            -h | --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
        esac
    done

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
        log_warning "iTerm2 não está instalado via Homebrew"

        # Check if app exists manually
        if check_installation; then
            log_warning "iTerm2 encontrado em /Applications mas não via Homebrew"
            echo ""
            log_output "${YELLOW}Deseja remover manualmente? (s/N)${NC}"
            read -r response

            if [[ "$response" =~ ^[sSyY]$ ]]; then
                rm -rf "/Applications/iTerm.app"
                log_success "iTerm2 removido com sucesso"
                return 0
            else
                log_info "Remoção cancelada"
                return 1
            fi
        else
            log_info "iTerm2 não está instalado"
            return 0
        fi
    fi

    local version=$(get_current_version)
    log_debug "Versão a ser removida: $version"

    # Confirm uninstallation
    if [ "$SKIP_CONFIRM" = false ]; then
        echo ""
        log_output "${YELLOW}Deseja realmente desinstalar o iTerm2 $version? (s/N)${NC}"
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    # Uninstall iTerm2
    log_info "Removendo iTerm2..."
    if ! homebrew_uninstall "$ITERM_HOMEBREW_CASK" "iTerm2"; then
        log_error "Falha ao desinstalar iTerm2"
        return 1
    fi

    # Verify removal
    if ! check_installation; then
        log_success "iTerm2 desinstalado com sucesso"
        remove_software_in_lock "iterm"
        log_debug "Aplicativo removido de /Applications"
    else
        log_warning "iTerm2 removido do Homebrew, mas arquivos podem permanecer"
    fi

    # Clean up preferences (optional)
    if [ "$SKIP_CONFIRM" = false ]; then
        echo ""
        log_output "${YELLOW}Deseja remover as preferências e configurações do iTerm2? (s/N)${NC}"
        read -r config_response

        if [[ "$config_response" =~ ^[sSyY]$ ]]; then
            rm -rf "$HOME/Library/Preferences/com.googlecode.iterm2.plist" 2> /dev/null || true
            log_debug "Preferências removidas: ~/Library/Preferences/com.googlecode.iterm2.plist"
            rm -rf "$HOME/Library/Application Support/iTerm2" 2> /dev/null || true
            log_debug "Dados removidos: ~/Library/Application Support/iTerm2"
            rm -rf "$HOME/Library/Saved Application State/com.googlecode.iterm2.savedState" 2> /dev/null || true
            log_debug "Estado removido"
            log_success "Preferências removidas"
        else
            log_info "Preferências mantidas"
        fi
    else
        # Auto-remove when --yes is used
        rm -rf "$HOME/Library/Preferences/com.googlecode.iterm2.plist" 2> /dev/null || true
        log_debug "Preferências removidas: ~/Library/Preferences/com.googlecode.iterm2.plist"
        rm -rf "$HOME/Library/Application Support/iTerm2" 2> /dev/null || true
        log_debug "Dados removidos: ~/Library/Application Support/iTerm2"
        rm -rf "$HOME/Library/Saved Application State/com.googlecode.iterm2.savedState" 2> /dev/null || true
        log_debug "Estado removido"
        log_info "Preferências removidas automaticamente"
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
