#!/usr/bin/env zsh
# Postman Update Functions

# Update Postman on macOS using Homebrew
update_postman_macos() {
    homebrew_update "$POSTMAN_HOMEBREW_CASK" "$POSTMAN_NAME"
}

# Update Postman on Linux using Flatpak
update_postman_linux() {
    flatpak_update "$FLATPAK_APP_ID" "$POSTMAN_NAME"
}
