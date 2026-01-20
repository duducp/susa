#!/bin/bash
# homebrew.sh - Library for managing applications via Homebrew
#
# Functions to install, update, remove and query applications
# distributed via Homebrew on macOS.
#
# Usage:
#   source "$LIB_DIR/homebrew.sh"
#
# Public functions:
#   homebrew_is_available           - Check if Homebrew is installed
#   homebrew_is_installed           - Check if an app is installed
#   homebrew_get_installed_version  - Get installed version of an app
#   homebrew_get_latest_version     - Get latest available version
#   homebrew_install                - Install an application from Homebrew
#   homebrew_update                 - Update an installed application
#   homebrew_uninstall              - Remove an installed application
#   homebrew_update_metadata        - Update Homebrew formulae

set -euo pipefail
IFS=$'\n\t'

# Check if Homebrew is installed on the system
#
# Returns:
#   0 if Homebrew is available
#   1 if Homebrew is not installed
homebrew_is_available() {
    command -v brew &> /dev/null
}

# Update Homebrew formulae
#
# Useful to ensure that the latest version information
# is available before querying or installing applications.
#
# Returns:
#   0 on success
#   1 on error
homebrew_update_metadata() {
    if ! homebrew_is_available; then
        log_debug "Homebrew não disponível, pulando atualização de metadados"
        return 0
    fi

    log_debug "Atualizando formulae do Homebrew..."
    if brew update 2> /dev/null; then
        log_debug "Metadados do Homebrew atualizados com sucesso"
        return 0
    else
        log_debug "Falha ao atualizar metadados do Homebrew"
        return 1
    fi
}

# Check if a Homebrew cask is installed
#
# Arguments:
#   $1 - Cask name (e.g.: visual-studio-code)
#
# Returns:
#   0 if the cask is installed
#   1 if the cask is not installed or error
homebrew_is_installed() {
    local cask_name="${1:-}"

    if [ -z "$cask_name" ]; then
        log_error "Nome do cask é obrigatório"
        return 1
    fi

    if ! homebrew_is_available; then
        return 1
    fi

    brew list --cask "$cask_name" &> /dev/null
}

# Get the installed version of a Homebrew cask
#
# Arguments:
#   $1 - Cask name (e.g.: visual-studio-code)
#
# Output:
#   Installed version or "unknown" if not installed/not found
#
# Returns:
#   0 always
homebrew_get_installed_version() {
    local cask_name="${1:-}"

    if [ -z "$cask_name" ]; then
        echo "unknown"
        return 0
    fi

    if ! homebrew_is_installed "$cask_name"; then
        echo "unknown"
        return 0
    fi

    local version=$(brew list --cask --versions "$cask_name" 2> /dev/null | awk '{print $2}' | head -1 || echo "unknown")
    echo "$version"
}

# Get the latest available version of a cask from Homebrew
#
# Arguments:
#   $1 - Cask name (e.g.: visual-studio-code)
#
# Output:
#   Latest version or "unknown" if not found
#
# Returns:
#   0 if version was found
#   1 on error
homebrew_get_latest_version() {
    local cask_name="${1:-}"

    if [ -z "$cask_name" ]; then
        log_error "Nome do cask é obrigatório"
        echo "unknown"
        return 1
    fi

    if ! homebrew_is_available; then
        log_error "Homebrew não está instalado"
        echo "unknown"
        return 1
    fi

    local version=$(brew info --cask "$cask_name" 2> /dev/null | grep -m1 "^${cask_name}:" | awk '{print $2}' || echo "unknown")

    if [ "$version" = "unknown" ] || [ -z "$version" ]; then
        echo "unknown"
        return 1
    fi

    echo "$version"
    return 0
}

# Install a cask from Homebrew
#
# Arguments:
#   $1 - Cask name (e.g.: visual-studio-code)
#   $2 - (Optional) Friendly name for logs (default: use cask name)
#
# Returns:
#   0 if installation was successful
#   1 on error
homebrew_install() {
    local cask_name="${1:-}"
    local app_name="${2:-$cask_name}"

    if [ -z "$cask_name" ]; then
        log_error "Nome do cask é obrigatório"
        return 1
    fi

    if ! homebrew_is_available; then
        log_error "Homebrew não está instalado. Por favor, instale-o primeiro:"
        log_output "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi

    # Check if already installed
    if homebrew_is_installed "$cask_name"; then
        local version=$(homebrew_get_installed_version "$cask_name")
        log_info "$app_name $version já está instalado"
        return 0
    fi

    # Install the cask
    log_info "Instalando $app_name via Homebrew..."
    log_debug "Cask: $cask_name"

    if ! brew install --cask "$cask_name"; then
        log_error "Falha ao instalar $app_name via Homebrew"
        return 1
    fi

    # Verify installation
    if homebrew_is_installed "$cask_name"; then
        local version=$(homebrew_get_installed_version "$cask_name")
        log_success "$app_name $version instalado com sucesso!"
        return 0
    else
        log_error "$app_name foi instalado mas não está disponível"
        return 1
    fi
}

# Update an installed Homebrew cask
#
# Arguments:
#   $1 - Cask name (e.g.: visual-studio-code)
#   $2 - (Optional) Friendly name for logs (default: use cask name)
#
# Returns:
#   0 if update was successful or already up to date
#   1 on error
homebrew_update() {
    local cask_name="${1:-}"
    local app_name="${2:-$cask_name}"

    if [ -z "$cask_name" ]; then
        log_error "Nome do cask é obrigatório"
        return 1
    fi

    if ! homebrew_is_available; then
        log_error "Homebrew não está instalado"
        return 1
    fi

    # Check if installed
    if ! homebrew_is_installed "$cask_name"; then
        log_error "$app_name não está instalado"
        return 1
    fi

    local current_version=$(homebrew_get_installed_version "$cask_name")
    log_debug "Versão atual: $current_version"

    # Update the cask
    log_info "Atualizando $app_name via Homebrew..."

    if brew upgrade --cask "$cask_name" 2> /dev/null; then
        local new_version=$(homebrew_get_installed_version "$cask_name")

        if [ "$current_version" = "$new_version" ]; then
            log_info "$app_name já estava na versão mais recente ($new_version)"
        else
            log_success "$app_name atualizado com sucesso para versão $new_version!"
        fi
        return 0
    else
        # If upgrade fails, it might already be up to date
        local new_version=$(homebrew_get_installed_version "$cask_name")
        if [ "$current_version" = "$new_version" ]; then
            log_info "$app_name já está na versão mais recente ($new_version)"
            return 0
        else
            log_error "Falha ao atualizar $app_name via Homebrew"
            return 1
        fi
    fi
}

# Remove an installed Homebrew cask
#
# Arguments:
#   $1 - Cask name (e.g.: visual-studio-code)
#   $2 - (Optional) Friendly name for logs (default: use cask name)
#
# Returns:
#   0 if removal was successful or cask was not installed
#   1 on error
homebrew_uninstall() {
    local cask_name="${1:-}"
    local app_name="${2:-$cask_name}"

    if [ -z "$cask_name" ]; then
        log_error "Nome do cask é obrigatório"
        return 1
    fi

    if ! homebrew_is_available; then
        log_error "Homebrew não está instalado"
        return 1
    fi

    # Check if installed
    if ! homebrew_is_installed "$cask_name"; then
        log_debug "$app_name não está instalado"
        return 0
    fi

    log_info "Removendo $app_name..."
    log_debug "Cask: $cask_name"

    if ! brew uninstall --cask "$cask_name" 2> /dev/null; then
        log_error "Falha ao remover $app_name via Homebrew"
        return 1
    fi

    # Verify removal
    if ! homebrew_is_installed "$cask_name"; then
        log_success "$app_name removido com sucesso!"
        return 0
    else
        log_error "Falha ao remover $app_name completamente"
        return 1
    fi
}
