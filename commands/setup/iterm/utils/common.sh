#!/bin/bash
# iTerm2 Common Utilities
# Shared functions used across install, update and uninstall

# Constants
ITERM_NAME="iTerm2"
ITERM_BIN_NAME="iterm2"
ITERM_HOMEBREW_CASK="iterm2"
ITERM_GITHUB_REPO="gnachman/iTerm2"

# Get latest iTerm2 version
get_latest_version() {
    # Try to get the latest version via Homebrew
    local latest_version=$(homebrew_get_latest_version "$ITERM_HOMEBREW_CASK")

    if [ -n "$latest_version" ] && [ "$latest_version" != "unknown" ]; then
        log_debug "Versão obtida via Homebrew: $latest_version"
        echo "$latest_version"
        return 0
    fi

    # If Homebrew fails, try via GitHub API as fallback
    log_debug "Homebrew falhou, tentando via API do GitHub..."
    latest_version=$(curl -s --max-time 10 --connect-timeout 5 https://api.github.com/repos/gnachman/iTerm2/releases/latest 2> /dev/null | grep '"tag_name":' | sed -E 's/.*"v([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')

    if [ -n "$latest_version" ]; then
        log_debug "Versão obtida via API do GitHub: $latest_version"
        echo "$latest_version"
        return 0
    fi

    # If both methods fail, notify user
    log_error "Não foi possível obter a versão mais recente do iTerm2"
    log_error "Verifique sua conexão com a internet e o Homebrew"
    return 1
}

# Get installed iTerm2 version
get_current_version() {
    if homebrew_is_installed "$ITERM_HOMEBREW_CASK"; then
        homebrew_get_installed_version "$ITERM_HOMEBREW_CASK"
    else
        echo ""
    fi
}

# Check if iTerm2 is installed
check_installation() {
    [ "$(uname)" = "Darwin" ] && [ -d "/Applications/iTerm.app" ]
}
