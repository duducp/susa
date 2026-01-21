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
    if is_mac; then
        homebrew_get_latest_version "$DBEAVER_HOMEBREW_CASK"
    else
        flatpak_get_latest_version "$FLATPAK_APP_ID"
    fi
}

# Get installed DBeaver version
get_current_version() {
    if check_installation; then
        if is_mac; then
            homebrew_get_installed_version "$DBEAVER_HOMEBREW_CASK"
        else
            flatpak_get_installed_version "$FLATPAK_APP_ID"
        fi
    else
        echo "desconhecida"
    fi
}

# Check if DBeaver is installed
check_installation() {
    if is_mac; then
        homebrew_is_installed "$DBEAVER_HOMEBREW_CASK"
    else
        flatpak_is_installed "$FLATPAK_APP_ID"
    fi
}
