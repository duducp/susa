#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

# Show additional info in command help
show_complement_help() {
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup lazypg uninstall          # Desinstala LazyPG"
    log_output "  susa setup lazypg uninstall -y       # Desinstala sem confirmação"
}

# Uninstall lazypg
uninstall_lazypg() {
    if ! check_installation; then
        log_warning "LazyPG não está instalado"
        return 0
    fi

    log_info "Desinstalando LazyPG..."

    if is_mac; then
        # Uninstall via Homebrew on macOS
        if ! homebrew_is_available; then
            log_error "Homebrew não está disponível"
            return 1
        fi

        if homebrew_uninstall "$LAZYPG_HOMEBREW_FORMULA" "LazyPG"; then
            log_success "LazyPG desinstalado com sucesso"
            remove_software_in_lock "$LAZYPG_NAME"
            return 0
        else
            log_error "Falha ao desinstalar LazyPG via Homebrew"
            return 1
        fi
    elif is_linux; then
        # Remove binary from /usr/local/bin on Linux
        local binary_path="/usr/local/bin/$LAZYPG_BIN_NAME"
        if [ -f "$binary_path" ]; then
            if [ -w "$(dirname "$binary_path")" ]; then
                rm -f "$binary_path"
            else
                sudo rm -f "$binary_path"
            fi
            log_success "LazyPG desinstalado com sucesso"
            remove_software_in_lock "$LAZYPG_NAME"
            return 0
        else
            log_warning "Binário do LazyPG não encontrado em $binary_path"
            return 0
        fi
    else
        log_error "Sistema operacional não suportado"
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
                log_error "Opção desconhecida: $1"
                log_output "Use ${LIGHT_CYAN}susa setup lazypg uninstall --help${NC} para ver as opções disponíveis"
                exit 1
                ;;
        esac
    done

    # Confirm uninstall
    if [ "$skip_confirm" = false ]; then
        log_warning "Deseja realmente desinstalar o LazyPG? (s/N)"
        read -r response
        if [[ ! "$response" =~ ^[SsYy]$ ]]; then
            log_info "Desinstalação cancelada"
            exit 0
        fi
    fi

    if ! uninstall_lazypg; then
        exit 1
    fi
}

[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
