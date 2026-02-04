#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"

# Get utilities directory
UTILS_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../utils"
source "$UTILS_DIR/common.sh"

# Help function
show_complement_help() {
    log_output "${LIGHT_GREEN}Detalhes da atualização:${NC}"
    log_output "  • macOS: Atualiza via Homebrew"
    log_output "  • Linux: Reinstala a versão mais recente do pacote oficial"
    log_output ""
    log_output "${LIGHT_GREEN}Nota:${NC}"
    log_output "  O Docker Desktop também possui atualização automática interna."
    log_output "  Este comando força a atualização via gerenciador de pacotes."
}

# Main update function
main() {
    log_info "Atualizando Docker Desktop..."

    # Check if Docker Desktop is installed
    if ! check_installation; then
        log_error "Docker Desktop não está instalado. Use 'susa setup docker-dektop install' para instalar."
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"

    # Detect OS and update
    if is_mac; then
        update_docker_desktop_macos
    else
        update_docker_desktop_linux
    fi

    # Verify update
    if check_installation; then
        local new_version=$(get_current_version)

        # Update version in lock file
        register_or_update_software_in_lock "$COMMAND_NAME" "$new_version"

        if [ "$current_version" = "$new_version" ]; then
            log_info "Docker Desktop já estava na versão mais recente ($current_version)"
        else
            log_success "Docker Desktop atualizado com sucesso para versão $new_version!"
        fi
    else
        log_error "Falha na atualização do Docker Desktop"
        return 1
    fi
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
