#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/flatpak.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

# Show additional info in command help
show_complement_help() {
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Flameshot é uma ferramenta poderosa e simples de captura de tela."
    log_output "  Oferece recursos de anotação, edição e compartilhamento de screenshots"
    log_output "  com interface intuitiva e atalhos de teclado customizáveis."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup flameshot install              # Instala o Flameshot"
    log_output "  susa setup flameshot install -v           # Instala com saída detalhada"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Abra pelo menu de aplicações ou execute: ${LIGHT_CYAN}flameshot${NC}"
    log_output "  Configure atalhos de teclado em: Configurações → Atalhos"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Captura de tela com seleção de área"
    log_output "  • Editor de imagens integrado"
    log_output "  • Anotações: setas, linhas, texto, formas"
    log_output "  • Atalhos de teclado customizáveis"
    log_output "  • Upload para serviços de compartilhamento"
}

# Install on macOS
install_macos() {
    homebrew_install "$FLAMESHOT_HOMEBREW_CASK" "$FLAMESHOT_NAME"
}

# Install on Linux
install_linux() {
    flatpak_install "$FLATPAK_APP_ID" "$FLAMESHOT_NAME"
}

# Main function
main() {
    log_info "Instalando Flameshot..."

    if check_installation; then
        local current_version=$(get_current_version)
        log_info "Flameshot $current_version já está instalado"
        log_info "Use 'susa setup flameshot update' para atualizar"
        return 0
    fi

    if is_mac; then
        install_macos
    else
        install_linux
    fi

    if check_installation; then
        local installed_version=$(get_current_version)
        register_or_update_software_in_lock "flameshot" "$installed_version"
        log_success "Flameshot $installed_version instalado com sucesso!"
    else
        log_error "Falha ao instalar Flameshot"
        return 1
    fi
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
