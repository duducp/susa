#!/usr/bin/env zsh
# NordPass Update Functions

# Update NordPass on macOS
update_nordpass_macos() {
    homebrew_update "$HOMEBREW_CASK" "$NORDPASS_NAME"
}

# Update NordPass on Linux
update_nordpass_linux() {
    snap_update "$SNAP_APP_NAME" "$NORDPASS_NAME"
}
