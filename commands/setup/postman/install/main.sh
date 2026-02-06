#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# Source libraries
UTILS_DIR="$(dirname "$0")/../utils"
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"
source "$UTILS_DIR/install.sh"

# Show help
show_complement_help() {
    log_output "${LIGHT_GREEN}Exemplo:${NC}"
    log_output "  susa setup postman install              # Instala o Postman"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  O Postman estará disponível no menu de aplicativos ou via:"
    log_output "    postman                 # Abre o Postman"
}

# Main function
main() {
    if check_installation; then
        log_info "$POSTMAN_NAME $(get_current_version) já está instalado."
        exit 0
    fi

    if is_mac; then
        install_postman_macos
    else
        install_postman_linux
    fi

    # Mark as installed
    local version=$(get_current_version)
    register_or_update_software_in_lock "$COMMAND_NAME" "$version"
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
