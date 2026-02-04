#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/shell.sh"
source "$UTILS_DIR/common.sh"

# Show additional info in category listing
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  --info          Mostra informações da instalação do Poetry"
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Poetry é um gerenciador de dependências e empacotamento para Python."
    log_output "  Facilita o gerenciamento de bibliotecas, criação de ambientes virtuais"
    log_output "  e publicação de pacotes Python de forma simplificada."
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Gerenciamento de dependências com resolução automática"
    log_output "  • Criação e gerenciamento de ambientes virtuais"
    log_output "  • Publicação simplificada de pacotes no PyPI"
    log_output "  • Arquivo pyproject.toml padronizado (PEP 518)"
    log_output "  • Lock file para reprodutibilidade"
    log_output ""
    log_output "${LIGHT_GREEN}Próximos passos (após instalação):${NC}"
    log_output "  ${LIGHT_CYAN}poetry new meu-projeto${NC}         # Criar novo projeto"
    log_output "  ${LIGHT_CYAN}poetry add requests${NC}            # Adicionar dependência"
    log_output "  ${LIGHT_CYAN}poetry install${NC}                # Instalar dependências"
    log_output "  ${LIGHT_CYAN}poetry run python script.py${NC}   # Executar script"
    log_output "  ${LIGHT_CYAN}poetry shell${NC}                  # Ativar ambiente virtual"
}

# Main function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --info)
                show_software_info
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                log_output ""
                log_output "Use ${LIGHT_CYAN}susa setup poetry --help${NC} para ver opções disponíveis"
                exit 1
                ;;
        esac
    done

    # If no arguments, show help
    display_help
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
