#!/bin/bash

source "$LIB_DIR/internal/json.sh"

# Get plugin info from lock file
get_plugin_info_from_lock() {
    local plugin_name="$1"
    local field="$2"
    local lock_file="$CLI_DIR/susa.lock"

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    case "$field" in
        version)
            json_get_field_from_array "$lock_file" ".plugins" "select(.name == \"$plugin_name\")" ".version"
            ;;
        commands)
            json_get_field_from_array "$lock_file" ".plugins" "select(.name == \"$plugin_name\")" ".commands"
            ;;
        categories)
            json_get_field_from_array "$lock_file" ".plugins" "select(.name == \"$plugin_name\")" ".categories"
            ;;
        *)
            return 1
            ;;
    esac
}
