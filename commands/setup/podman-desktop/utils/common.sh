#!/bin/bash
# Podman Desktop Common Utilities
# Shared functions used across install, update and uninstall

# Constants
PODMAN_DESKTOP_NAME="Podman Desktop"
PODMAN_BIN_NAME="podman-desktop"
FLATPAK_APP_ID="io.podman_desktop.PodmanDesktop"
HOMEBREW_CASK="podman-desktop"

# Get latest version
get_latest_version() {
    if is_mac; then
        homebrew_get_latest_version "$HOMEBREW_CASK"
    else
        flatpak_get_latest_version "$FLATPAK_APP_ID"
    fi
}

# Get installed Podman Desktop version
get_current_version() {
    if check_installation; then
        if is_mac; then
            homebrew_get_installed_version "$HOMEBREW_CASK"
        else
            flatpak_get_installed_version "$FLATPAK_APP_ID"
        fi
    fi
}

# Check if Podman Desktop is installed
check_installation() {
    if is_mac; then
        homebrew_is_installed "$HOMEBREW_CASK"
    else
        flatpak_is_installed "$FLATPAK_APP_ID"
    fi
}
