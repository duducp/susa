#!/usr/bin/env zsh
# Postman Installation Functions

# Install Postman on macOS using Homebrew
install_postman_macos() {
    homebrew_install "$POSTMAN_HOMEBREW_CASK" "$POSTMAN_NAME"
}

# Install Postman on Linux using Flatpak
install_postman_linux() {
    flatpak_install "$FLATPAK_APP_ID" "$POSTMAN_NAME"
}
