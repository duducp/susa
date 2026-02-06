#!/usr/bin/env zsh
# NordPass Uninstall Functions

# Internal uninstall (without prompts)
remove_nordpass_internal() {
    if is_mac; then
        homebrew_uninstall "$HOMEBREW_CASK" "$NORDPASS_NAME" > /dev/null 2>&1 || true
    else
        snap_uninstall "$SNAP_APP_NAME" "$NORDPASS_NAME" > /dev/null 2>&1 || true
    fi
}
