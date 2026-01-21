#!/bin/bash
# Postman Uninstall Functions

# Uninstall Postman on macOS using Homebrew
uninstall_postman_macos() {
    homebrew_uninstall "$POSTMAN_HOMEBREW_CASK" "$POSTMAN_NAME"
}

# Uninstall Postman on Linux using Flatpak
uninstall_postman_linux() {
    flatpak_uninstall "$FLATPAK_APP_ID" "$POSTMAN_NAME"
}
