#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/homebrew.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/shell.sh"
source "$UTILS_DIR/common.sh"

# Show additional info in category listing
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  --info          Mostra informações da instalação do Podman"
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Podman é um motor de container open-source para desenvolvimento,"
    log_output "  gerenciamento e execução de containers OCI. É uma alternativa"
    log_output "  daemon-less e rootless ao Docker."
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Sem daemon (daemonless) - mais leve e seguro"
    log_output "  • Rootless - executa containers sem privilégios root"
    log_output "  • Compatível com Docker - mesma CLI e formato de imagens"
    log_output "  • Suporte a pods (similar ao Kubernetes)"
    log_output "  • Integração com systemd para gerenciamento de serviços"
    log_output ""
    log_output "${LIGHT_GREEN}Próximos passos (após instalação):${NC}"
    log_output "  ${LIGHT_CYAN}podman --version${NC}                  # Verifica a instalação"
    log_output "  ${LIGHT_CYAN}podman run hello-world${NC}            # Teste com container simples"
    log_output "  ${LIGHT_CYAN}podman images${NC}                     # Lista imagens disponíveis"
    log_output "  ${LIGHT_CYAN}podman ps${NC}                         # Lista containers em execução"
    log_output "  ${LIGHT_CYAN}podman compose${NC}                    # Gerencia aplicações multi-container"
    log_output ""
    log_output "${LIGHT_GREEN}Interface Gráfica:${NC}"
    log_output "  Se preferir gerenciar containers com interface gráfica:"
    log_output "    ${LIGHT_CYAN}susa setup podman-desktop${NC}     # Instala Podman Desktop"
    log_output ""
    log_output "${LIGHT_GREEN}Compatibilidade com Docker:${NC}"
    log_output "  Para usar comandos Docker com Podman, configure via Podman Desktop"
    log_output "  (Preferences > Docker Compatibility)"
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
                log_output "Use ${LIGHT_CYAN}susa setup podman --help${NC} para ver opções disponíveis"
                exit 1
                ;;
        esac
    done

    # If no arguments, show help
    display_help
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
