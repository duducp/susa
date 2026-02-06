#!/usr/bin/env zsh
# flatpak.sh - Library for managing applications via Flatpak
#
# Functions to install, update, remove and query applications
# distributed via Flatpak from the Flathub repository.
#
# Usage:
#   source "$LIB_DIR/flatpak.sh"
#
# Public functions:
#   flatpak_is_available           - Check if Flatpak is installed
#   flatpak_ensure_flathub         - Ensure Flathub is configured
#   flatpak_is_installed           - Check if an app is installed
#   flatpak_get_installed_version  - Get installed version of an app
#   flatpak_get_latest_version     - Get latest available version
#   flatpak_install                - Install an application from Flathub
#   flatpak_update                 - Update an installed application
#   flatpak_uninstall              - Remove an installed application
#   flatpak_update_metadata        - Update Flathub metadata

# Check if Flatpak is installed on the system
#
# Returns:
#   0 if Flatpak is available
#   1 if Flatpak is not installed
flatpak_is_available() {
    command -v flatpak &> /dev/null
}

# Ensure the Flathub repository is configured
#
# Adds Flathub as a remote if not already configured.
# Uses user-level installation (--user).
#
# Returns:
#   0 if Flathub is configured or was successfully added
#   1 on error
flatpak_ensure_flathub() {
    if ! flatpak_is_available; then
        log_error "Flatpak não está instalado. Por favor, instale o Flatpak primeiro."
        log_info "Veja: https://flatpak.org/setup/"
        return 1
    fi

    # Check if flathub is already added
    if flatpak remotes --user 2> /dev/null | grep -q "^flathub"; then
        log_debug "Repositório Flathub já está configurado"
        return 0
    fi

    log_info "Adicionando repositório Flathub..."
    if ! flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
        log_error "Falha ao adicionar repositório Flathub"
        return 1
    fi

    log_success "Repositório Flathub adicionado com sucesso"
    return 0
}

# Update Flathub repository metadata
#
# Useful to ensure that the latest version information
# is available before querying or installing applications.
#
# Returns:
#   0 always (metadata update is not critical)
flatpak_update_metadata() {
    if ! flatpak_is_available; then
        log_debug "Flatpak não disponível, pulando atualização de metadados"
        return 0
    fi

    log_debug "Atualizando metadados do Flathub..."
    flatpak update --appstream --user 2> /dev/null || log_debug "Metadados já estão atualizados"
    return 0
}

# Check if a Flatpak application is installed
#
# Arguments:
#   $1 - Application ID (e.g.: io.podman_desktop.PodmanDesktop)
#
# Returns:
#   0 if the application is installed
#   1 if the application is not installed or error
flatpak_is_installed() {
    local app_id="${1:-}"

    if [ -z "$app_id" ]; then
        log_error "ID da aplicação é obrigatório"
        return 1
    fi

    if ! flatpak_is_available; then
        return 1
    fi

    flatpak list --user --app --columns=application 2> /dev/null | grep -q "^${app_id}$"
}

# Get the installed version of a Flatpak application
#
# Arguments:
#   $1 - Application ID (e.g.: io.podman_desktop.PodmanDesktop)
#
# Output:
#   Installed version or "unknown" if not installed/not found
#
# Returns:
#   0 always
flatpak_get_installed_version() {
    local app_id="${1:-}"

    if [ -z "$app_id" ]; then
        echo "unknown"
        return 0
    fi

    if ! flatpak_is_installed "$app_id"; then
        echo "unknown"
        return 0
    fi

    local version=$(flatpak info --user "$app_id" 2> /dev/null | grep -E "^\s*Version:" | head -1 | awk '{print $2}' || echo "unknown")
    echo "$version"
}

# Get the latest available version of an application from Flathub
#
# Arguments:
#   $1 - Application ID (e.g.: io.podman_desktop.PodmanDesktop)
#
# Output:
#   Latest version or "unknown" if not found
#
# Returns:
#   0 if version was found
#   1 on error
flatpak_get_latest_version() {
    local app_id="${1:-}"

    if [ -z "$app_id" ]; then
        log_error "ID da aplicação é obrigatório"
        echo "unknown"
        return 1
    fi

    if ! flatpak_is_available; then
        log_error "Flatpak não está instalado"
        echo "unknown"
        return 1
    fi

    # Check if Flathub is configured
    if ! flatpak remotes --user 2> /dev/null | grep -q "^flathub"; then
        log_error "Repositório Flathub não configurado"
        echo "unknown"
        return 1
    fi

    # Try to get from pending updates first
    local version=$(flatpak remote-ls --updates --user flathub --columns=application,version 2> /dev/null | grep "^${app_id}" | awk '{print $2}')

    # If not found in updates, search in remote-info
    if [ -z "$version" ]; then
        version=$(flatpak remote-info flathub --user "$app_id" 2> /dev/null | grep -E "^\s*Version:" | head -1 | awk '{print $2}')
    fi

    # If still not found, try Flathub API
    if [ -z "$version" ]; then
        log_debug "Tentando obter versão via API do Flathub para $app_id"
        version=$(curl -fsSL "https://flathub.org/api/v2/appstream/${app_id}" 2> /dev/null | jq -r '.releases[0].version // empty' 2> /dev/null)
    fi

    # If still not found, return unknown
    if [ -z "$version" ]; then
        echo "unknown"
        return 1
    fi

    echo "$version"
    return 0
}

# Install an application from Flathub
#
# Arguments:
#   $1 - Application ID (e.g.: io.podman_desktop.PodmanDesktop)
#   $2 - (Optional) Friendly name for logs (default: use ID)
#
# Returns:
#   0 if installation was successful
#   1 on error
flatpak_install() {
    local app_id="${1:-}"
    local app_name="${2:-$app_id}"

    if [ -z "$app_id" ]; then
        log_error "Application ID is required"
        return 1
    fi

    # Ensure Flathub is configured
    if ! flatpak_ensure_flathub; then
        return 1
    fi

    # Check if already installed
    if flatpak_is_installed "$app_id"; then
        local version=$(flatpak_get_installed_version "$app_id")
        log_info "$app_name $version já está instalado"
        return 0
    fi

    # Update metadata
    flatpak_update_metadata

    # Install the application
    log_info "Instalando $app_name via Flatpak..."
    log_debug "ID da aplicação: $app_id"

    if ! flatpak install -y --user flathub "$app_id"; then
        log_error "Falha ao instalar $app_name via Flatpak"
        return 1
    fi

    # Verify installation
    if flatpak_is_installed "$app_id"; then
        local version=$(flatpak_get_installed_version "$app_id")
        return 0
    else
        log_error "$app_name foi instalado mas não está disponível"
        return 1
    fi
}

# Update an installed Flatpak application
#
# Arguments:
#   $1 - Application ID (e.g.: io.podman_desktop.PodmanDesktop)
#   $2 - (Optional) Friendly name for logs (default: use ID)
#
# Returns:
#   0 if update was successful or already up to date
#   1 on error
flatpak_update() {
    local app_id="${1:-}"
    local app_name="${2:-$app_id}"

    if [ -z "$app_id" ]; then
        log_error "ID da aplicação é obrigatório"
        return 1
    fi

    # Check if installed
    if ! flatpak_is_installed "$app_id"; then
        log_error "$app_name não está instalado"
        return 1
    fi

    local current_version=$(flatpak_get_installed_version "$app_id")
    log_debug "Versão atual: $current_version"

    # Update the application
    log_info "Atualizando $app_name via Flatpak..."

    if ! flatpak update -y --user "$app_id"; then
        log_error "Falha ao atualizar $app_name via Flatpak"
        return 1
    fi

    # Check new version
    local new_version=$(flatpak_get_installed_version "$app_id")

    if [ "$current_version" = "$new_version" ]; then
        log_info "$app_name já estava na versão mais recente ($new_version)"
    else
        log_success "$app_name atualizado com sucesso para versão $new_version!"
    fi

    return 0
}

# Remove an installed Flatpak application
#
# Arguments:
#   $1 - Application ID (e.g.: io.podman_desktop.PodmanDesktop)
#   $2 - (Optional) Friendly name for logs (default: use ID)
#
# Returns:
#   0 if removal was successful or app was not installed
#   1 on error
flatpak_uninstall() {
    local app_id="${1:-}"
    local app_name="${2:-$app_id}"

    if [ -z "$app_id" ]; then
        log_error "ID da aplicação é obrigatório"
        return 1
    fi

    # Check if installed
    if ! flatpak_is_installed "$app_id"; then
        log_debug "$app_name não está instalado"
        return 0
    fi

    log_info "Removendo $app_name..."
    log_debug "ID da aplicação: $app_id"

    # Encerra processos da aplicação antes de desinstalar
    log_debug "Encerrando processos de $app_name..."
    flatpak kill --user "$app_id" 2> /dev/null || true

    if ! flatpak uninstall --delete-data -y --user "$app_id" 2> /dev/null; then
        log_error "Falha ao remover $app_name via Flatpak"
        return 1
    fi

    # Verify removal
    if ! flatpak_is_installed "$app_id"; then
        log_success "$app_name removido com sucesso!"
        return 0
    else
        log_error "Falha ao remover $app_name completamente"
        return 1
    fi
}
