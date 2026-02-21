#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/shell.sh"
source "$LIB_DIR/internal/config.sh"
source "$LIB_DIR/internal/completion.sh"

# Help function
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  -v, --verbose     Modo verbose (debug)"
    log_output "  -h, --help        Exibe esta mensagem de ajuda"
    log_output ""
    log_output "${LIGHT_GREEN}Informações Exibidas:${NC}"
    log_output "  • Nome e versão da CLI"
    log_output "  • Diretório de instalação"
    log_output "  • Localização do link simbólico do executável"
    log_output "  • Ambiente de shell atual"
    log_output "  • Status de completação do shell"
    log_output "  • Detalhes do sistema operacional"
    log_output "  • Status das dependências necessárias"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa self info                # Exibe todas as informações da CLI"
    log_output "  susa self info --help         # Exibe esta ajuda"
}

# Main function
main() {
    # Find symlink path
    SYMLINK_PATH=""
    if command -v susa &> /dev/null; then
        SUSA_BIN=$(command -v susa)
        if [[ -L "$SUSA_BIN" ]]; then
            SYMLINK_PATH="$SUSA_BIN -> $(readlink -f "$SUSA_BIN")"
        else
            SYMLINK_PATH="$SUSA_BIN (executável direto)"
        fi
    else
        SYMLINK_PATH="Não encontrado no PATH"
    fi

    # Get completion status using library functions
    CURRENT_SHELL=$(detect_shell_type)
    log_debug "Shell detectado: $CURRENT_SHELL"

    COMPLETION_STATUS_INFO=$(get_completion_status "$CURRENT_SHELL")
    IFS=':' read -r COMPLETION_INSTALLED COMPLETION_DETAILS_REST <<< "$COMPLETION_STATUS_INFO"

    # OS Info
    OS_TYPE=$(uname -s)
    ARCH=$(uname -m)
    KERNEL=$(uname -r)
    DISTRO="Desconhecida"
    if [ -f /etc/os-release ]; then
        # Subshell to avoid polluting environment
        DISTRO=$(grep "^PRETTY_NAME=" /etc/os-release | cut -d= -f2 | tr -d '"')
        [ -z "$DISTRO" ] && DISTRO=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        DISTRO="macOS $(sw_vers -productVersion)"
    fi

    # Display information
    log_output "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    log_output "${BOLD}${CYAN}║${NC}                ${WHITE}DETALHES DA INSTALAÇÃO${NC}                    ${BOLD}${CYAN}║${NC}"
    log_output "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    log_output ""

    # CLI Section
    log_output "  ${BOLD}${MAGENTA}🚀 CLI Info${NC}"
    log_output "  ${DIM}──────────────────────────────────────────────────────────${NC}"
    log_output "  ${BOLD}Nome:${NC}             ${GREEN}$(get_config_field $GLOBAL_CONFIG_FILE name)${NC}"
    log_output "  ${BOLD}Versão:${NC}           ${GREEN}$(show_number_version)${NC}"
    log_output "  ${BOLD}Diretório:${NC}        ${YELLOW}$CLI_DIR${NC}"
    log_output "  ${BOLD}Executável:${NC}       ${YELLOW}$SYMLINK_PATH${NC}"
    log_output ""

    # Shell Section
    log_output "  ${BOLD}${MAGENTA}🐚 Ambiente de Shell${NC}"
    log_output "  ${DIM}──────────────────────────────────────────────────────────${NC}"
    log_output "  ${BOLD}Shell Atual:${NC}      ${CYAN}$CURRENT_SHELL${NC}"
    if [[ "$COMPLETION_INSTALLED" == "Installed" ]]; then
        log_output "  ${BOLD}Autocompletar:${NC}    ${GREEN}● Ativo${NC}"
    else
        log_output "  ${BOLD}Autocompletar:${NC}    ${RED}○ Inativo${NC}"
    fi
    log_output ""

    # System Section
    log_output "  ${BOLD}${MAGENTA}💻 Sistema Operacional${NC}"
    log_output "  ${DIM}──────────────────────────────────────────────────────────${NC}"
    log_output "  ${BOLD}Distribuição:${NC}     ${WHITE}$DISTRO${NC}"
    log_output "  ${BOLD}Arquitetura:${NC}      ${WHITE}$ARCH${NC}"
    log_output "  ${BOLD}Kernel:${NC}           ${DIM}$KERNEL${NC}"
    log_output ""

    # Dependencies Section
    log_output "  ${BOLD}${MAGENTA}🛠️  Dependências Core${NC}"
    log_output "  ${DIM}──────────────────────────────────────────────────────────${NC}"

    local deps=("git" "jq" "curl" "gum")
    local deps_line="  "
    for dep in "${deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            deps_line+="${GREEN}✓${NC} ${BOLD}$dep${NC}  "
        else
            deps_line+="${RED}✗${NC} ${BOLD}$dep${NC}  "
        fi
    done
    log_output "$deps_line"
    log_output ""
}

# Execute main only if not showing help
if [ "${SUSA_SHOW_HELP:-}" != "1" ]; then
    main "$@"
fi
