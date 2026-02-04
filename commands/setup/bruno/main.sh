#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/flatpak.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

# Show additional info in category listing
show_complement_help() {
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Bruno é um cliente de API open-source rápido e amigável para Git."
    log_output "  Alternativa ao Postman/Insomnia, armazena coleções diretamente"
    log_output "  em uma pasta no seu sistema de arquivos."
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Offline-first - sem sincronização em nuvem"
    log_output "  • Armazena coleções em pastas no sistema de arquivos"
    log_output "  • Versionamento com Git"
    log_output "  • Suporte a REST, GraphQL e gRPC"
    log_output ""
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  --info          Mostra informações do Bruno instalado"
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
                log_output "Use ${LIGHT_CYAN}susa setup bruno --help${NC} para ver opções disponíveis"
                exit 1
                ;;
        esac
    done

    # If no arguments, show help
    display_help
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
