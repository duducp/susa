#!/bin/bash
# VSCode Common Utilities
# Shared functions used across install, update and uninstall

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
