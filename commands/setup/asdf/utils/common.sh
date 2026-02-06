#!/usr/bin/env zsh
# ASDF Common Utilities
# Shared functions used across install, update and uninstall

# Source libraries
source "$LIB_DIR/github.sh"

# Constants
ASDF_NAME="ASDF"
ASDF_BIN_NAME="asdf"
ASDF_REPO="asdf-vm/asdf"
ASDF_INSTALL_DIR="$HOME/.asdf"
LOCAL_BIN_DIR="$HOME/.local/bin"

# Get latest version
get_latest_version() {
    github_get_latest_version "$ASDF_REPO"
}

# Get installed ASDF version
get_current_version() {
    local asdf_dir="${ASDF_INSTALL_DIR}"

    if [ -f "$asdf_dir/bin/$ASDF_BIN_NAME" ]; then
        "$asdf_dir/bin/$ASDF_BIN_NAME" --version 2> /dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo ""
    elif check_installation; then
        $ASDF_BIN_NAME --version 2> /dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo ""
    else
        echo ""
    fi
}

# Check if ASDF is installed
check_installation() {
    command -v $ASDF_BIN_NAME &> /dev/null
}

# Show additional ASDF-specific information
show_additional_info() {
    if ! check_installation; then
        return
    fi

    # List installed plugins
    local plugins=$(asdf plugin list 2> /dev/null | wc -l | xargs)
    if [ "$plugins" != "0" ]; then
        log_output "  ${CYAN}Plugins:${NC} $plugins instalados"

        # Show plugins with versions
        local plugin_list=$(asdf plugin list 2> /dev/null)
        if [ -n "$plugin_list" ]; then
            log_output "  ${CYAN}Linguagens:${NC}"
            while IFS= read -r plugin; do
                local versions=$(asdf list "$plugin" 2> /dev/null | wc -l | xargs)
                if [ "$versions" != "0" ]; then
                    log_output "    • $plugin ($versions versões)"
                fi
            done <<< "$plugin_list"
        fi
    else
        log_output "  ${CYAN}Plugins:${NC} nenhum instalado"
    fi
}
