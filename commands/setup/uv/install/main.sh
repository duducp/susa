#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"

# Get utilities directory
UTILS_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../utils"
source "$UTILS_DIR/common.sh"

# Help function
show_complement_help() {
    log_output "${LIGHT_GREEN}Detalhes da instalação:${NC}"
    log_output "  • Download da versão mais recente do GitHub"
    log_output "  • Verificação de checksum SHA256"
    log_output "  • Instalação em ~/.local/bin"
    log_output "  • Configuração automática do shell"
    log_output ""
    log_output "${LIGHT_GREEN}Binários instalados:${NC}"
    log_output "  • uv  - Gerenciador de pacotes Python"
    log_output "  • uvx - Executar ferramentas Python sem instalação"
    log_output ""
    log_output "${LIGHT_GREEN}Após a instalação:${NC}"
    log_output "  Reinicie o terminal ou execute:"
    log_output "    ${LIGHT_CYAN}source ~/.bashrc${NC}   (Bash)"
    log_output "    ${LIGHT_CYAN}source ~/.zshrc${NC}    (Zsh)"
}

# Main installation function
main() {
    if check_installation; then
        log_info "UV $(get_current_version) já está instalado."
        exit 0
    fi

    log_info "Iniciando instalação do UV..."

    # Get latest version
    local uv_version=$(get_latest_version)
    if [ $? -ne 0 ] || [ -z "$uv_version" ]; then
        return 1
    fi

    # Detect platform
    local platform=$(detect_uv_platform)
    if [ $? -ne 0 ]; then
        return 1
    fi

    local bin_dir="$LOCAL_BIN_DIR"
    mkdir -p "$bin_dir"

    # Download and extract
    if ! download_and_extract_uv "$uv_version" "$platform" "$bin_dir"; then
        return 1
    fi

    # Configure shell
    configure_shell "$bin_dir"

    # Setup environment for current session
    setup_uv_environment "$bin_dir"

    # Verify installation
    if check_installation; then
        local version=$(get_current_version)
        log_success "UV $version instalado com sucesso!"
        register_or_update_software_in_lock "$COMMAND_NAME" "$version"

        echo ""
        echo "Próximos passos:"
        local shell_config=$(detect_shell_config)
        log_output "  1. Reinicie o terminal ou execute: ${LIGHT_CYAN}source $shell_config${NC}"
        log_output "  2. Crie um novo projeto: ${LIGHT_CYAN}uv init meu-projeto${NC}"
        log_output "  3. Use ${LIGHT_CYAN}susa setup uv --help${NC} para mais informações"

        # Show uvx info
        echo ""
        log_output "${LIGHT_GREEN}Dica:${NC} Use ${LIGHT_CYAN}uvx${NC} para executar ferramentas Python sem instalação:"
        echo "  uvx ruff check .    # Executar ruff"
        log_output "  uvx black .         # Executar black"

        return 0
    else
        log_error "UV foi instalado mas não está disponível no PATH"
        local shell_config=$(detect_shell_config)
        log_info "Tente reiniciar o terminal ou executar: source $shell_config"
        return 1
    fi
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
