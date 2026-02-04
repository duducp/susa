#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

# Show additional info in command help
show_complement_help() {
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Remove completamente o Lazygit do sistema"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup lazygit uninstall            # Remove o Lazygit"
    log_output "  susa setup lazygit uninstall -v         # Remove com saída detalhada"
}

# Uninstall on macOS
uninstall_macos() {
    homebrew_uninstall "$HOMEBREW_FORMULA" "$SOFTWARE_NAME"
    return $?
}

# Uninstall on Linux
uninstall_linux() {
    local install_dir="$HOME/.local/bin"
    local binary_path="$install_dir/$BIN_NAME"

    if [ -f "$binary_path" ]; then
        log_info "Removendo $SOFTWARE_NAME de $install_dir..."
        rm -f "$binary_path"
        log_success "✓ Binário removido"
        return 0
    else
        log_warning "Binário não encontrado em $binary_path"
        return 1
    fi
}

# Main function
main() {
    if ! check_installation; then
        log_warning "$SOFTWARE_NAME não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)
    log_info "Desinstalando $SOFTWARE_NAME (versão: $current_version)..."

    local uninstall_result=1
    if is_mac; then
        uninstall_macos
        uninstall_result=$?
    elif is_linux; then
        uninstall_linux
        uninstall_result=$?
    else
        log_error "Sistema operacional não suportado"
        return 1
    fi

    if [ $uninstall_result -eq 0 ] && ! check_installation; then
        remove_software_in_lock "lazygit"
        log_success "✓ $SOFTWARE_NAME desinstalado com sucesso!"
    else
        log_error "✗ Falha ao desinstalar $SOFTWARE_NAME"
        return 1
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
