#!/bin/bash

UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/utils"

# Source libraries only if not just showing complement help
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/flatpak.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

# Show additional info in category listing
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  --info          Mostra informações do DBeaver instalado"
}

# Main function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --info)
                show_software_info "dbeaver" "$DBEAVER_BIN_NAME"
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                log_output ""
                log_output "Use ${LIGHT_CYAN}susa setup dbeaver --help${NC} para ver opções disponíveis"
                exit 1
                ;;
        esac
    done

    # If no arguments, show help
    display_help
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
