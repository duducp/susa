#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n | --number)
                show_number_version
                exit 0
                ;;
            *)
                log_error "Argumento inválido: $1"
                log_output ""
                show_version
                exit 1
                ;;
        esac
    done

    # Default: show full version
    log_debug "Exibindo versão do Susa CLI"
    show_version
}

# Execute main only if not showing help
if [ "${SUSA_SHOW_HELP:-}" != "1" ]; then
    main "$@"
fi
