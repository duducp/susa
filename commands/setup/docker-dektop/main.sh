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
    log_output "  Docker Desktop é uma aplicação completa com interface gráfica para"
    log_output "  gerenciar containers Docker. Inclui Docker Engine, Docker CLI,"
    log_output "  Docker Compose, Kubernetes e muito mais."
    log_output ""
    log_output "${LIGHT_GREEN}⚠️  Consideração Importante:${NC}"
    log_output "  O Docker Desktop possui requisitos de licenciamento para uso comercial."
    log_output "  Para alternativa open source, considere ${LIGHT_CYAN}Podman Desktop${NC}:"
    log_output "    ${LIGHT_CYAN}susa setup podman-desktop install${NC}"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Interface gráfica intuitiva"
    log_output "  • Dashboard para gerenciar containers e imagens"
    log_output "  • Suporte a Kubernetes integrado"
    log_output "  • Docker Compose incluído"
    log_output "  • Extensões para ampliar funcionalidades"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  O Docker Desktop estará disponível no menu de aplicativos."
    log_output "  A primeira execução pode levar alguns minutos para inicializar."
}

# Main function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --info)
                if is_mac; then
                    show_software_info "docker-dektop" "/Applications/Docker.app/Contents/MacOS/Docker Desktop"
                else
                    show_software_info "docker-dektop"
                fi
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
