#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries only if not just showing complement help
if [ "${SUSA_SKIP_MAIN:-}" != "1" ]; then
    source "$LIB_DIR/internal/installations.sh"
    source "$LIB_DIR/github.sh"

    # Source utils
    UTILS_DIR="$(dirname "${BASH_SOURCE[0]}")/utils"
    source "$UTILS_DIR/common.sh"
fi

# Show additional info in category listing
show_complement_help() {
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  --info          Mostra informações do VS Code instalado"
}

# Main function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --info)
                show_software_info "code" "$VSCODE_BIN_NAME"
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                log_output ""
                log_output "Use ${LIGHT_CYAN}susa setup vscode --help${NC} para ver opções disponíveis"
                exit 1
                ;;
        esac
    done

    # If no arguments, show help
    show_help
}

# Execute main function only if not skipped (for show_complement_help)
if [ "${SUSA_SKIP_MAIN:-}" != "1" ]; then
    main "$@"
fi
