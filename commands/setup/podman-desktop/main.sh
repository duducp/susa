#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/flatpak.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

# Show additional info in category listing
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  --info          Mostra informações do Podman Desktop instalado"
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Podman Desktop é uma interface gráfica para gerenciar containers,"
    log_output "  imagens e pods Podman. Oferece uma experiência visual amigável"
    log_output "  para trabalhar com containers sem necessidade de linha de comando."
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Interface gráfica intuitiva para Podman"
    log_output "  • Gerenciamento de containers, imagens e volumes"
    log_output "  • Suporte a Kubernetes pods"
    log_output "  • Alternativa open-source ao Docker Desktop"
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
                log_output "Use ${LIGHT_CYAN}susa setup podman-desktop --help${NC} para ver opções disponíveis"
                exit 1
                ;;
        esac
    done

    # If no arguments, show help
    display_help
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
