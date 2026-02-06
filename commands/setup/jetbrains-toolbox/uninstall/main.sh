#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/../utils"
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$UTILS_DIR/common.sh"

SKIP_CONFIRM=false

# Main uninstall function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y | --yes)
                SKIP_CONFIRM=true
                shift
                ;;
            -h | --help)
                # Help is handled by the CLI framework
                exit 0
                ;;
            *)
                log_error "Opção inválida: $1"
                log_output "Use 'susa setup jetbrains-toolbox uninstall --help' para ver opções disponíveis"
                exit 1
                ;;
        esac
    done

    log_info "Desinstalando JetBrains Toolbox..."

    # Check if installed
    if ! check_installation; then
        log_info "JetBrains Toolbox não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)
    log_debug "Versão a ser removida: $current_version"
    if is_mac; then
        log_debug "Localização: /Applications/JetBrains Toolbox.app"
    else
        log_debug "Localização: $LOCAL_BIN_DIR/jetbrains-toolbox"
    fi

    echo ""
    if [ "$SKIP_CONFIRM" = false ]; then
        log_output "${YELLOW}Deseja realmente desinstalar o JetBrains Toolbox $current_version? (s/N)${NC}"
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    # Stop Toolbox if running
    log_debug "Encerrando JetBrains Toolbox..."
    if is_mac; then
        osascript -e 'quit app "JetBrains Toolbox"' 2> /dev/null || true
    else
        # Kill only the jetbrains-toolbox binary, not this script
        pkill -9 -f "^$LOCAL_BIN_DIR/jetbrains-toolbox" 2> /dev/null || true
    fi

    # Remove binary/app
    if is_mac; then
        local binary_location="/Applications/JetBrains Toolbox.app"
        if [ -d "$binary_location" ]; then
            rm -rf "$binary_location"
            log_debug "Aplicativo removido: $binary_location"
        fi
    else
        local binary_location="$LOCAL_BIN_DIR/jetbrains-toolbox"
        if [ -f "$binary_location" ]; then
            rm -f "$binary_location"
            log_debug "Binário removido: $binary_location"
        fi

        # Remove desktop entry
        local desktop_file="$HOME/.local/share/applications/jetbrains-toolbox.desktop"
        if [ -f "$desktop_file" ]; then
            rm -f "$desktop_file"
            log_debug "Atalho removido: $desktop_file"
        fi
    fi

    # Remove installation directory with version file
    local install_dir
    if is_mac; then
        install_dir="$TOOLBOX_MAC_INSTALL_DIR"
    else
        install_dir="$TOOLBOX_LINUX_INSTALL_DIR"
    fi

    if [ -d "$install_dir" ]; then
        rm -rf "$install_dir"
    fi

    # Verify removal
    if ! check_installation; then
        log_success "JetBrains Toolbox desinstalado com sucesso!"
        remove_software_in_lock "jetbrains-toolbox"
    else
        log_error "Falha ao desinstalar JetBrains Toolbox completamente"
        return 1
    fi

    # Ask about removing IDEs installed by Toolbox
    if [ "$SKIP_CONFIRM" = false ]; then
        echo ""
        log_output "${YELLOW}Deseja remover também as IDEs instaladas pelo Toolbox (IntelliJ, PyCharm, etc)? (s/N)${NC}"
        read -r ides_response

        if [[ "$ides_response" =~ ^[sSyY]$ ]]; then
            log_info "Removendo IDEs instaladas..."

            if is_mac; then
                # Remove IDEs directory
                rm -rf "$HOME/Library/Application Support/JetBrains/Toolbox" 2> /dev/null || true
                log_debug "IDEs removidas: ~/Library/Application Support/JetBrains/Toolbox"

                # Remove logs
                rm -rf "$HOME/Library/Logs/JetBrains" 2> /dev/null || true
                log_debug "Logs removidos: ~/Library/Logs/JetBrains"
            else
                # Remove IDEs directory (apps, channels, etc)
                rm -rf "$HOME/.local/share/JetBrains/Toolbox" 2> /dev/null || true
                log_debug "IDEs removidas: ~/.local/share/JetBrains/Toolbox"

                # Remove cache
                rm -rf "$HOME/.cache/JetBrains/Toolbox" 2> /dev/null || true
                log_debug "Cache removido: ~/.cache/JetBrains/Toolbox"

                # Remove logs
                rm -rf "$HOME/.local/share/JetBrains/Toolbox/logs" 2> /dev/null || true
                log_debug "Logs removidos"
            fi

            log_success "IDEs instaladas removidas"
        else
            log_info "IDEs mantidas"
        fi
    else
        # Auto-remove when --yes is used
        log_info "Removendo IDEs instaladas automaticamente..."

        if is_mac; then
            rm -rf "$HOME/Library/Application Support/JetBrains/Toolbox" 2> /dev/null || true
            log_debug "IDEs removidas: ~/Library/Application Support/JetBrains/Toolbox"
            rm -rf "$HOME/Library/Logs/JetBrains" 2> /dev/null || true
            log_debug "Logs removidos: ~/Library/Logs/JetBrains"
        else
            rm -rf "$HOME/.local/share/JetBrains/Toolbox" 2> /dev/null || true
            log_debug "IDEs removidas: ~/.local/share/JetBrains/Toolbox"
            rm -rf "$HOME/.cache/JetBrains/Toolbox" 2> /dev/null || true
            log_debug "Cache removido: ~/.cache/JetBrains/Toolbox"
        fi

        log_info "IDEs instaladas removidas automaticamente"
    fi
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
