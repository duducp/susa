#!/usr/bin/env zsh

# Source required libraries
source "$LIB_DIR/os.sh"
source "$LIB_DIR/homebrew.sh"
source "$LIB_DIR/github.sh"

# Constants
readonly SOFTWARE_NAME="Lazygit"
readonly GITHUB_REPO="jesseduffield/lazygit"
readonly HOMEBREW_FORMULA="lazygit"
readonly BIN_NAME="lazygit"

# Check if software is installed
check_installation() {
    if is_mac; then
        homebrew_is_installed "$HOMEBREW_FORMULA"
    else
        command -v "$BIN_NAME" &> /dev/null
    fi
}

# Get current installed version
get_current_version() {
    if ! check_installation; then
        echo "desconhecida"
        return 1
    fi

    if is_mac; then
        homebrew_get_installed_version "$HOMEBREW_FORMULA"
    else
        # Try to get version from lock file first
        local lock_version=$(get_installed_version "lazygit" 2> /dev/null)
        if [ -n "$lock_version" ] && [ "$lock_version" != "desconhecida" ]; then
            echo "$lock_version"
        else
            # Fallback to command version
            $BIN_NAME --version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida"
        fi
    fi
}

# Get latest available version
get_latest_version() {
    if is_mac; then
        homebrew_get_latest_version "$HOMEBREW_FORMULA"
    else
        github_get_latest_version "$GITHUB_REPO" "true"
    fi
}
