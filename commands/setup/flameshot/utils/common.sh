#!/bin/bash
# Flameshot Common Utilities
# Shared functions used across install, update and uninstall

# Constants
FLAMESHOT_NAME="Flameshot"
FLAMESHOT_HOMEBREW_FORMULA="flameshot"
FLATPAK_APP_ID="org.flameshot.Flameshot"

# Get latest version
get_latest_version() {
    if is_mac; then
        homebrew_get_latest_version "$FLAMESHOT_HOMEBREW_FORMULA"
    else
        flatpak_get_latest_version "$FLATPAK_APP_ID"
    fi
}

# Get installed Flameshot version
get_current_version() {
    if check_installation; then
        if is_mac; then
            homebrew_get_installed_version "$FLAMESHOT_HOMEBREW_FORMULA"
        else
            flatpak_get_installed_version "$FLATPAK_APP_ID"
        fi
    else
        echo "desconhecida"
    fi
}

# Check if Flameshot is installed
check_installation() {
    if is_mac; then
        homebrew_is_installed "$FLAMESHOT_HOMEBREW_FORMULA"
    else
        flatpak_is_installed "$FLATPAK_APP_ID"
    fi
}
