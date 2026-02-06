#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# Source libraries
UTILS_DIR="$(dirname "$0")/../utils"
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"
source "$UTILS_DIR/update.sh"

# Main function
main() {
    log_info "Atualizando Postman..."

    if ! check_installation; then
        log_warning "$POSTMAN_NAME não está instalado."
        log_info "Use: susa setup postman install"
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"

    if is_mac; then
        update_postman_macos
    else
        update_postman_linux
    fi

    local new_version=$(get_current_version)
    log_success "$POSTMAN_NAME atualizado para versão $new_version"

    # Update lock file
    register_or_update_software_in_lock "$COMMAND_NAME" "$new_version"
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
