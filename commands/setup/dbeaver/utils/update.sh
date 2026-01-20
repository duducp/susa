#!/bin/bash
# DBeaver Update Functions

# Update DBeaver on macOS using Homebrew
update_dbeaver_macos() {
    homebrew_update "$DBEAVER_HOMEBREW_CASK" "$DBEAVER_NAME"
}

# Update DBeaver on Linux using Flatpak
update_dbeaver_linux() {
    flatpak_update "$FLATPAK_APP_ID" "$DBEAVER_NAME"
}
