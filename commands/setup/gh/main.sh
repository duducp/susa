#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$UTILS_DIR/common.sh"

# Show additional info in category listing
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  --info          Mostra informações da instalação"
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Ferramenta oficial de linha de comando do GitHub que permite"
    log_output "  gerenciar issues, PRs, repositórios e mais diretamente do terminal"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup gh install              # Instala o GitHub CLI"
    log_output "  susa setup gh update               # Atualiza o GitHub CLI"
    log_output "  susa setup gh uninstall            # Desinstala o GitHub CLI"
    log_output "  susa setup gh --info               # Mostra status da instalação"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Gerenciamento de issues e pull requests"
    log_output "  • Criação e clonagem de repositórios"
    log_output "  • Execução de GitHub Actions"
    log_output "  • Autenticação via OAuth"
    log_output "  • Extensões customizadas"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Execute: ${LIGHT_CYAN}gh auth login${NC} para autenticar sua conta GitHub"
    log_output "  Depois: ${LIGHT_CYAN}gh repo list${NC} para listar seus repositórios"
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
                log_output "Use ${LIGHT_CYAN}susa setup gh --help${NC} para ver opções disponíveis"
                exit 1
                ;;
        esac
    done

    # If no arguments, show help
    display_help
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
