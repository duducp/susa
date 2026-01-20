#!/bin/bash
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
    case "$OS_TYPE" in
        macos)
            homebrew_get_latest_version "$HOMEBREW_CASK"
            ;;
        *)
            # Get from Snap Store for Linux
            snap_get_latest_version "$SNAP_APP_NAME"
            ;;
    esac
}

# Get installed version
get_current_version() {
    if check_installation; then
        case "$OS_TYPE" in
            macos)
                homebrew_get_installed_version "$HOMEBREW_CASK"
                ;;
            *)
                # Get version from Snap
                snap_get_installed_version "$SNAP_APP_NAME"
                ;;
        esac
    else
        echo "unknown"
    fi
}

# Check if NordPass is installed
check_installation() {
    case "$OS_TYPE" in
        macos)
            homebrew_is_installed "$HOMEBREW_CASK"
            ;;
        *)
            snap_is_installed "$SNAP_APP_NAME"
            ;;
    esac
}
