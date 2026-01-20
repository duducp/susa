#!/bin/bash
# VSCode Common Utilities
# Shared functions used across install, update and uninstall

# Constants
VSCODE_NAME="Visual Studio Code"
VSCODE_REPO="microsoft/vscode"
VSCODE_BIN_NAME="code"
VSCODE_HOMEBREW_CASK="visual-studio-code"
VSCODE_APT_KEY_URL="https://packages.microsoft.com/keys/microsoft.asc"
VSCODE_APT_REPO="https://packages.microsoft.com/repos/code"
VSCODE_RPM_KEY_URL="https://packages.microsoft.com/keys/microsoft.asc"
VSCODE_RPM_REPO_URL="https://packages.microsoft.com/yumrepos/vscode"
VSCODE_DEB_PACKAGE="code"
VSCODE_RPM_PACKAGE="code"
VSCODE_ARCH_AUR="visual-studio-code-bin"
VSCODE_ARCH_COMMUNITY="code"

# Get latest version from GitHub
get_latest_version() {
    local version=$(github_get_latest_version "$VSCODE_REPO" 2> /dev/null)

    if [ -n "$version" ] && [ "$version" != "null" ]; then
        echo "$version"
    else
        echo "desconhecida"
    fi
}

# Get installed VS Code version
get_current_version() {
    if check_installation; then
        local version=$($VSCODE_BIN_NAME --version 2> /dev/null | head -1 || echo "desconhecida")
        if [ "$version" != "desconhecida" ]; then
            echo "$version"
        fi
    else
        echo "desconhecida"
    fi
}

# Check if VS Code is installed
check_installation() {
    command -v $VSCODE_BIN_NAME &> /dev/null
}
