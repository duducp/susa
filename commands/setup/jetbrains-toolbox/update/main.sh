#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/../utils"
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$UTILS_DIR/common.sh"

# Main update function
main() {
    log_info "Atualizando JetBrains Toolbox..."

    # Check if installed
    if ! check_installation; then
        log_error "JetBrains Toolbox não está instalado. Use 'susa setup jetbrains-toolbox install' para instalar."
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"
    if is_mac; then
        log_debug "Localização: /Applications/JetBrains Toolbox.app"
    else
        log_debug "Localização: $LOCAL_BIN_DIR/jetbrains-toolbox"
    fi

    # Get latest version
    local latest_version=$(get_latest_version)
    if [ $? -ne 0 ] || [ -z "$latest_version" ]; then
        return 1
    fi

    if [ "$current_version" = "$latest_version" ]; then
        log_info "Você já possui a versão mais recente instalada ($current_version)"
        return 0
    fi

    log_info "Atualizando de $current_version para $latest_version..."

    # Detect OS
    local os_arch=$(detect_os_and_arch)
    if [ $? -ne 0 ]; then
        return 1
    fi

    local os_name="${os_arch%:*}"

    # Stop Toolbox if running
    log_info "Nota: Feche o JetBrains Toolbox se estiver em execução antes de continuar."
    sleep 5

    # Remove old installation
    if [ "$os_name" = "mac" ]; then
        local binary_location="/Applications/JetBrains Toolbox.app"
        rm -rf "$binary_location"
    else
        local binary_location="$LOCAL_BIN_DIR/jetbrains-toolbox"
        rm -f "$binary_location"
    fi

    # Install new version using install subcommand
    source "$(dirname "$0")/../install/main.sh"

    local install_result=$?

    if [ $install_result -eq 0 ]; then
        log_success "JetBrains Toolbox atualizado com sucesso para versão $latest_version!"
        register_or_update_software_in_lock "jetbrains-toolbox" "$latest_version"
        log_debug "Atualização concluída"
    else
        log_error "Falha na atualização do JetBrains Toolbox"
        return $install_result
    fi
}

# Run main function (skip if showing help)
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
