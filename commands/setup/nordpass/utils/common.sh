#!/usr/bin/env zsh
# NordPass Common Utilities
# Shared functions used across install, update and uninstall

# Constants
NORDPASS_NAME="NordPass"
NORDPASS_BIN_NAME="nordpass"
SNAP_APP_NAME="nordpass"
HOMEBREW_CASK="nordpass"
APP_MACOS="/Applications/NordPass.app"

# Get latest version
get_latest_version() {
    if is_mac; then
        homebrew_get_latest_version "$HOMEBREW_CASK"
    else
        # Get from Snap Store for Linux
        snap_get_latest_version "$SNAP_APP_NAME"
    fi
}

# Get installed version
get_current_version() {
    if check_installation; then
        if is_mac; then
            homebrew_get_installed_version "$HOMEBREW_CASK"
        else
            # Get version from Snap
            snap_get_installed_version "$SNAP_APP_NAME"
        fi
    else
        echo "unknown"
    fi
}

# Check if NordPass is installed
check_installation() {
    if is_mac; then
        homebrew_is_installed "$HOMEBREW_CASK"
    else
        snap_is_installed "$SNAP_APP_NAME"
    fi
}
