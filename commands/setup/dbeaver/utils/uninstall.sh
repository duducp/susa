#!/usr/bin/env zsh
# DBeaver Uninstall Functions

# Uninstall DBeaver on macOS using Homebrew
uninstall_dbeaver_macos() {
    homebrew_uninstall "$DBEAVER_HOMEBREW_CASK" "$DBEAVER_NAME"
}

# Uninstall DBeaver on Linux using Flatpak
uninstall_dbeaver_linux() {
    flatpak_uninstall "$FLATPAK_APP_ID" "$DBEAVER_NAME"
}
