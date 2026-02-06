#!/usr/bin/env zsh
# Bruno Common Utilities
# Shared functions used across install, update and uninstall

# Constants
BRUNO_NAME="Bruno"
BRUNO_REPO="usebruno/bruno"
BRUNO_BIN_NAME="bruno"
BRUNO_HOMEBREW_CASK="bruno"
FLATPAK_APP_ID="com.usebruno.Bruno"

# Get latest version
get_latest_version() {
    if is_mac; then
        homebrew_get_latest_version "$BRUNO_HOMEBREW_CASK"
    else
        flatpak_get_latest_version "$FLATPAK_APP_ID"
    fi
}

# Get installed Bruno version
get_current_version() {
    if check_installation; then
        if is_mac; then
            homebrew_get_installed_version "$BRUNO_HOMEBREW_CASK"
        else
            flatpak_get_installed_version "$FLATPAK_APP_ID"
        fi
    fi
}

# Check if Bruno is installed
check_installation() {
    if is_mac; then
        homebrew_is_installed "$BRUNO_HOMEBREW_CASK"
    else
        flatpak_is_installed "$FLATPAK_APP_ID"
    fi
}
