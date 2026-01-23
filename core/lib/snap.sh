#!/bin/bash
# snap.sh - Library for managing applications via Snap
#
# Functions to install, update, remove and query applications
# distributed via Snap from the Snap Store.
#
# Usage:
#   source "$LIB_DIR/snap.sh"
#
# Public functions:
#   snap_is_available           - Check if Snap is installed
#   snap_is_installed           - Check if an app is installed
#   snap_get_installed_version  - Get installed version of an app
#   snap_get_latest_version     - Get latest available version
#   snap_install                - Install an application from Snap Store
#   snap_update                 - Update an installed application
#   snap_uninstall              - Remove an installed application
#   snap_refresh_metadata       - Refresh Snap Store metadata

set -euo pipefail
IFS=$'\n\t'

# Check if Snap is installed on the system
#
# Returns:
#   0 if Snap is available
#   1 if Snap is not installed
snap_is_available() {
    command -v snap &> /dev/null
}

# Refresh Snap Store repository metadata
#
# Useful to ensure that the latest version information
# is available before querying or installing applications.
#
# Returns:
#   0 always (metadata update is not critical)
snap_refresh_metadata() {
    if ! snap_is_available; then
        log_debug "Snap não disponível, pulando atualização de metadados"
        return 0
    fi

    log_debug "Atualizando metadados do Snap Store..."
    snap refresh --list &> /dev/null || log_debug "Metadados já estão atualizados"
    return 0
}

# Check if a Snap application is installed
#
# Arguments:
#   $1 - Application name (e.g.: podman-desktop)
#
# Returns:
#   0 if the application is installed
#   1 if the application is not installed or error
snap_is_installed() {
    local app_name="${1:-}"

    if [ -z "$app_name" ]; then
        log_error "Nome da aplicação é obrigatório"
        return 1
    fi

    if ! snap_is_available; then
        return 1
    fi

    snap list 2> /dev/null | grep -q "^${app_name}\s"
}

# Get the installed version of a Snap application
#
# Arguments:
#   $1 - Application name (e.g.: podman-desktop)
#
# Output:
#   Installed version or "unknown" if not installed/not found
#
# Returns:
#   0 always
snap_get_installed_version() {
    local app_name="${1:-}"

    if [ -z "$app_name" ]; then
        echo "unknown"
        return 0
    fi

    if ! snap_is_installed "$app_name"; then
        echo "unknown"
        return 0
    fi

    local version=$(snap list "$app_name" 2> /dev/null | tail -n +2 | awk '{print $2}' || echo "unknown")
    echo "$version"
}

# Get the latest available version of an application from Snap Store
#
# Arguments:
#   $1 - Application name (e.g.: podman-desktop)
#
# Output:
#   Latest version or "unknown" if not found
#
# Returns:
#   0 if version was found
#   1 on error
snap_get_latest_version() {
    local app_name="${1:-}"

    if [ -z "$app_name" ]; then
        log_error "Nome da aplicação é obrigatório"
        echo "unknown"
        return 1
    fi

    if ! snap_is_available; then
        log_error "Snap não está instalado"
        echo "unknown"
        return 1
    fi

    # Try to get from snap info
    local version=$(snap info "$app_name" 2> /dev/null | grep -E "^\s*latest/stable:" | awk '{print $2}' || echo "")

    # If not found, return unknown
    if [ -z "$version" ]; then
        echo "unknown"
        return 1
    fi

    echo "$version"
    return 0
}

# Install an application from Snap Store
#
# Arguments:
#   $1 - Application name (e.g.: podman-desktop)
#   $2 - (Optional) Friendly name for logs (default: use name)
#   $3 - (Optional) Channel (default: stable)
#   $4 - (Optional) Classic confinement flag (true/false, default: false)
#
# Returns:
#   0 if installation was successful
#   1 on error
snap_install() {
    local app_name="${1:-}"
    local friendly_name="${2:-$app_name}"
    local channel="${3:-stable}"
    local classic="${4:-false}"

    if [ -z "$app_name" ]; then
        log_error "Nome da aplicação é obrigatório"
        return 1
    fi

    # Check if Snap is available
    if ! snap_is_available; then
        log_error "Snap não está instalado. Por favor, instale o Snap primeiro."
        log_info "Veja: https://snapcraft.io/docs/installing-snapd"
        return 1
    fi

    # Check if already installed
    if snap_is_installed "$app_name"; then
        local version=$(snap_get_installed_version "$app_name")
        log_info "$friendly_name $version já está instalado"
        return 0
    fi

    # Update metadata
    snap_refresh_metadata

    # Install the application
    log_info "Instalando $friendly_name via Snap..."
    log_debug "Nome da aplicação: $app_name"
    log_debug "Canal: $channel"

    local install_cmd="snap install $app_name --channel=$channel"
    if [ "$classic" = "true" ]; then
        install_cmd="$install_cmd --classic"
        log_debug "Modo: classic"
    fi

    if ! eval "sudo $install_cmd"; then
        log_error "Falha ao instalar $friendly_name via Snap"
        return 1
    fi

    # Verify installation
    if snap_is_installed "$app_name"; then
        local version=$(snap_get_installed_version "$app_name")
        return 0
    else
        log_error "$friendly_name foi instalado mas não está disponível"
        return 1
    fi
}

# Update an installed Snap application
#
# Arguments:
#   $1 - Application name (e.g.: podman-desktop)
#   $2 - (Optional) Friendly name for logs (default: use name)
#   $3 - (Optional) Channel (default: stable)
#
# Returns:
#   0 if update was successful or already up to date
#   1 on error
snap_update() {
    local app_name="${1:-}"
    local friendly_name="${2:-$app_name}"
    local channel="${3:-stable}"

    if [ -z "$app_name" ]; then
        log_error "Nome da aplicação é obrigatório"
        return 1
    fi

    # Check if installed
    if ! snap_is_installed "$app_name"; then
        log_error "$friendly_name não está instalado"
        return 1
    fi

    local current_version=$(snap_get_installed_version "$app_name")
    log_debug "Versão atual: $current_version"

    # Update the application
    log_info "Atualizando $friendly_name via Snap..."

    local update_cmd="snap refresh $app_name --channel=$channel"
    if ! eval "sudo $update_cmd"; then
        log_error "Falha ao atualizar $friendly_name via Snap"
        return 1
    fi

    # Check new version
    local new_version=$(snap_get_installed_version "$app_name")

    if [ "$current_version" = "$new_version" ]; then
        log_info "$friendly_name já estava na versão mais recente ($new_version)"
    else
        log_success "$friendly_name atualizado com sucesso para versão $new_version!"
    fi

    return 0
}

# Remove an installed Snap application
#
# Arguments:
#   $1 - Application name (e.g.: podman-desktop)
#   $2 - (Optional) Friendly name for logs (default: use name)
#
# Returns:
#   0 if removal was successful or app was not installed
#   1 on error
snap_uninstall() {
    local app_name="${1:-}"
    local friendly_name="${2:-$app_name}"

    if [ -z "$app_name" ]; then
        log_error "Nome da aplicação é obrigatório"
        return 1
    fi

    # Check if installed
    if ! snap_is_installed "$app_name"; then
        log_debug "$friendly_name não está instalado"
        return 0
    fi

    log_info "Removendo $friendly_name..."
    log_debug "Nome da aplicação: $app_name"

    if ! sudo snap remove --purge "$app_name" 2> /dev/null; then
        log_error "Falha ao remover $friendly_name via Snap"
        return 1
    fi

    # Verify removal
    if ! snap_is_installed "$app_name"; then
        log_success "$friendly_name removido com sucesso!"
        return 0
    else
        log_error "Falha ao remover $friendly_name completamente"
        return 1
    fi
}

# Get detailed information about a Snap package
#
# Arguments:
#   $1 - Application name (e.g.: podman-desktop)
#
# Output:
#   Detailed information from snap info
#
# Returns:
#   0 if information was retrieved
#   1 on error
snap_info() {
    local app_name="${1:-}"

    if [ -z "$app_name" ]; then
        log_error "Nome da aplicação é obrigatório"
        return 1
    fi

    if ! snap_is_available; then
        log_error "Snap não está instalado"
        return 1
    fi

    snap info "$app_name"
}

# List all installed Snap packages
#
# Output:
#   List of installed packages with versions
#
# Returns:
#   0 always
snap_list_installed() {
    if ! snap_is_available; then
        log_error "Snap não está instalado"
        return 1
    fi

    snap list
}
