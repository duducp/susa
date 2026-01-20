#!/bin/bash
# DBeaver Installation Functions

# Install DBeaver on macOS using Homebrew
install_dbeaver_macos() {
    homebrew_install "$DBEAVER_HOMEBREW_CASK" "$DBEAVER_NAME"
}

# Install DBeaver on Linux using Flatpak
install_dbeaver_linux() {
    flatpak_install "$FLATPAK_APP_ID" "$DBEAVER_NAME"
}
