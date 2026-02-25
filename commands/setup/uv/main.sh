#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"

# Get utilities directory
UTILS_DIR="$(dirname "$(readlink -f "$0")")/utils"
source "$UTILS_DIR/common.sh"

# Help function
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  --info          Mostra informações da instalação"
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  UV (by Astral) é um gerenciador de pacotes e projetos Python extremamente"
    log_output "  rápido, escrito em Rust. Substitui pip, pip-tools, pipx, poetry, pyenv,"
    log_output "  virtualenv e muito mais, com velocidade 10-100x mais rápida."
    log_output ""
    log_output "${LIGHT_GREEN}Principais comandos:${NC}"
    log_output "  ${LIGHT_CYAN}uv init meu-projeto${NC}      # Criar novo projeto"
    log_output "  ${LIGHT_CYAN}uv add requests${NC}          # Adicionar dependência"
    log_output "  ${LIGHT_CYAN}uv sync${NC}                  # Instalar dependências"
    log_output "  ${LIGHT_CYAN}uv run python script.py${NC}  # Executar script"
    log_output ""
    log_output "${LIGHT_GREEN}Usando uvx (executar sem instalar):${NC}"
    log_output "  ${LIGHT_CYAN}uvx ruff check .${NC}         # Executar ruff"
    log_output "  ${LIGHT_CYAN}uvx black .${NC}              # Executar black"
    log_output ""
    log_output "${LIGHT_GREEN}Após a instalação:${NC}"
    log_output "  Reinicie o terminal ou execute:"
    log_output "    ${LIGHT_CYAN}source ~/.bashrc${NC}   (para Bash)"
    log_output "    ${LIGHT_CYAN}source ~/.zshrc${NC}    (para Zsh)"
}

# Main function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --info)
                show_software_info "uv"
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Show help if no arguments
    show_usage
    exit 0
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
