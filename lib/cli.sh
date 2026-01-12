#!/bin/bash

# Obtém o diretório da lib
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/color.sh"
source "$LIB_DIR/yaml.sh"

# --- CLI Helper Functions ---

show_version() {
    local name=$(get_yaml_global_field "$YAML_CONFIG" "name")
    local version=$(get_yaml_global_field "$YAML_CONFIG" "version")
    echo -e "${BOLD}$name${NC} (version ${GRAY}$version${NC})"
}

show_usage() {
    local command=$(get_yaml_global_field "$YAML_CONFIG" "command")
    local args="${*:+ $*}"
    echo -e "${LIGHT_GREEN}Usage:${NC} ${LIGHT_CYAN}${command}${args}${NC} ${CYAN}<command> [options]${NC}"
}
