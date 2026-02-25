#!/usr/bin/env zsh

# Source required libraries
source "$LIB_DIR/os.sh"
source "$LIB_DIR/homebrew.sh"
source "$LIB_DIR/github.sh"

# Constants
readonly SOFTWARE_NAME="GitHub CLI"
readonly GITHUB_REPO="cli/cli"
readonly HOMEBREW_FORMULA="gh"
readonly BIN_NAME="gh"

# Check if software is installed
check_installation() {
    command -v "$BIN_NAME" &> /dev/null
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
        local lock_version=$(get_installed_version "gh" 2> /dev/null)
        if [ -n "$lock_version" ] && [ "$lock_version" != "desconhecida" ]; then
            echo "$lock_version"
        else
            # Fallback to command version
            $BIN_NAME --version 2> /dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "desconhecida"
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
