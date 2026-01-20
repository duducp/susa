#!/bin/bash
# NordPass Installation Functions

# Install on macOS using Homebrew
install_nordpass_macos() {
    homebrew_install "$HOMEBREW_CASK" "$NORDPASS_NAME"
}

# Install on Linux using Snap
install_nordpass_linux() {
    snap_install "$SNAP_APP_NAME" "$NORDPASS_NAME"
}
