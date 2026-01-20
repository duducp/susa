#!/bin/bash
# DBeaver Common Utilities
# Shared functions used across install, update and uninstall

# Constants
DBEAVER_NAME="DBeaver"
DBEAVER_BIN_NAME="dbeaver"
DBEAVER_GITHUB_REPO="dbeaver/dbeaver"
DBEAVER_INSTALL_DIR="/opt/dbeaver"
DBEAVER_PACKAGE_NAME="dbeaver-ce"
DBEAVER_HOMEBREW_CASK="dbeaver-community"
DBEAVER_APT_REPO="https://dbeaver.io/debs/dbeaver-ce"
DBEAVER_APT_KEY_URL="https://dbeaver.io/debs/dbeaver.gpg.key"
FLATPAK_APP_ID="io.dbeaver.DBeaverCommunity"

# Get latest version
get_latest_version() {
    case "$OS_TYPE" in
        macos)
            homebrew_get_latest_version "$DBEAVER_HOMEBREW_CASK"
            ;;
        *)
            flatpak_get_latest_version "$FLATPAK_APP_ID"
            ;;
    esac
}

# Get installed DBeaver version
get_current_version() {
    if check_installation; then
        case "$OS_TYPE" in
            macos)
                homebrew_get_installed_version "$DBEAVER_HOMEBREW_CASK"
                ;;
            *)
                flatpak_get_installed_version "$FLATPAK_APP_ID"
                ;;
        esac
    else
        echo "desconhecida"
    fi
}

# Check if DBeaver is installed
check_installation() {
    case "$OS_TYPE" in
        macos)
            homebrew_is_installed "$DBEAVER_HOMEBREW_CASK"
            ;;
        *)
            flatpak_is_installed "$FLATPAK_APP_ID"
            ;;
    esac
}
