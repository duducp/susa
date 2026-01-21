#!/bin/bash
# Postman Common Utilities
# Shared functions used across install, update and uninstall

# Source libraries
source "$LIB_DIR/homebrew.sh"
source "$LIB_DIR/flatpak.sh"

# Constants
POSTMAN_NAME="Postman"
POSTMAN_BIN_NAME="postman"
POSTMAN_HOMEBREW_CASK="postman"
FLATPAK_APP_ID="com.getpostman.Postman"

# Get latest version
get_latest_version() {
    case "$OS_TYPE" in
        macos)
            homebrew_get_latest_version "$POSTMAN_HOMEBREW_CASK"
            ;;
        *)
            flatpak_get_latest_version "$FLATPAK_APP_ID"
            ;;
    esac
}

# Get installed Postman version
get_current_version() {
    if check_installation; then
        case "$OS_TYPE" in
            macos)
                homebrew_get_installed_version "$POSTMAN_HOMEBREW_CASK"
                ;;
            *)
                flatpak_get_installed_version "$FLATPAK_APP_ID"
                ;;
        esac
    else
        echo "desconhecida"
    fi
}

# Check if Postman is installed
check_installation() {
    case "$OS_TYPE" in
        macos)
            homebrew_is_installed "$POSTMAN_HOMEBREW_CASK"
            ;;
        *)
            flatpak_is_installed "$FLATPAK_APP_ID"
            ;;
    esac
}
