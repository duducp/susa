#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

# Show additional info in command help
show_complement_help() {
    log_output "${LIGHT_GREEN}O que faz:${NC}"
    log_output "  Atualiza o LazyPG para a versão mais recente disponível."
    log_output ""
    log_output "  ${YELLOW}macOS:${NC} Verifica se há nova versão antes de atualizar via Homebrew"
    log_output "  ${YELLOW}Linux:${NC} Sempre baixa e instala a última versão disponível"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup lazypg update            # Atualiza LazyPG"
    log_output "  susa setup lazypg update -v         # Atualiza com saída detalhada"
}

# Update lazypg on macOS using Homebrew
update_lazypg_macos() {
    log_info "Verificando atualizações via Homebrew..."

    if ! homebrew_is_installed "$LAZYPG_HOMEBREW_FORMULA"; then
        log_error "LazyPG não está instalado via Homebrew"
        return 1
    fi

    # homebrew_update will check if there's a new version available
    if homebrew_update "$LAZYPG_HOMEBREW_FORMULA" "LazyPG"; then
        return 0
    else
        log_info "LazyPG já está na versão mais recente"
        return 0
    fi
}

# Main function
main() {
    log_info "Atualizando LazyPG..."

    if ! check_installation; then
        log_error "LazyPG não está instalado."
        log_output "Use ${LIGHT_CYAN}susa setup lazypg install${NC} para instalar"
        return 1
    fi

    local current_version=$(get_current_version)
    if [ -n "$current_version" ]; then
        log_info "Versão atual: $current_version"
    else
        log_info "Versão atual: desconhecida"
    fi

    # Update based on OS
    if is_mac; then
        update_lazypg_macos || return 1
    else
        install_or_update_lazypg_linux || return 1
    fi

    # Verify update and register in lock
    if check_installation; then
        local new_version=$(get_current_version)

        # For Linux, use the exported version if detection fails
        if [ -z "$new_version" ] && [ -n "${INSTALLED_LAZYPG_VERSION:-}" ]; then
            new_version="$INSTALLED_LAZYPG_VERSION"
        fi

        if [ -n "$new_version" ]; then
            register_or_update_software_in_lock "$LAZYPG_NAME" "$new_version"

            if [ -n "$current_version" ] && [ "$current_version" = "$new_version" ]; then
                log_info "LazyPG já estava na versão mais recente ($current_version)"
            else
                log_success "LazyPG atualizado com sucesso!"
                if [ -n "$new_version" ]; then
                    log_info "Nova versão: $new_version"
                fi
            fi
        else
            log_warning "Não foi possível detectar a nova versão instalada"
        fi
    else
        log_error "Falha na atualização do LazyPG"
        return 1
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
