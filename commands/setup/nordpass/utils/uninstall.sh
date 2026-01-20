#!/bin/bash
# NordPass Uninstall Functions

# Internal uninstall (without prompts)
remove_nordpass_internal() {
    case "$OS_TYPE" in
        macos)
            homebrew_uninstall "$HOMEBREW_CASK" "$NORDPASS_NAME" > /dev/null 2>&1 || true
            ;;
        *)
            snap_uninstall "$SNAP_APP_NAME" "$NORDPASS_NAME" > /dev/null 2>&1 || true
            ;;
    esac
}
