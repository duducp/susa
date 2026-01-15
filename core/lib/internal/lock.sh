#!/bin/bash

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
            yq eval ".plugins[] | select(.name == \"$plugin_name\") | .version" "$lock_file" 2> /dev/null | head -1
            ;;
        commands)
            yq eval ".plugins[] | select(.name == \"$plugin_name\") | .commands" "$lock_file" 2> /dev/null | head -1
            ;;
        categories)
            yq eval ".plugins[] | select(.name == \"$plugin_name\") | .categories" "$lock_file" 2> /dev/null | head -1
            ;;
        *)
            return 1
            ;;
    esac
}
