#!/bin/bash

source "$LIB_DIR/internal/json.sh"

# Updates the lock file (creates if doesn't exist)
update_lock_file() {
    log_info "Atualizando o lock..."
    log_debug "Executando: $CORE_DIR/susa self lock"

    if "$CORE_DIR/susa" self lock > /dev/null 2>&1; then
        log_debug "Lock file atualizado com sucesso"
        return 0
    else
        log_error "Não foi possível atualizar o susa.lock"
        log_debug "Você pode precisar executar: susa self lock"
        return 1
    fi
}

# Adds all plugins from registry to lock JSON
# Args: json_data
# Returns: updated json_data with plugins added
add_plugins_to_lock() {
    local json_data="$1"
    local registry_file="$PLUGINS_DIR/registry.json"

    # Check if registry exists
    if [ ! -f "$registry_file" ]; then
        echo "$json_data"
        return 0
    fi

    # Get all plugins from registry
    local all_plugins=$(jq -r '.plugins[] | .name + "|" + (.dev // false | tostring) + "|" + (.source // "") + "|" + (.directory // "")' "$registry_file" 2> /dev/null)

    while IFS='|' read -r plugin_name is_dev_str plugin_source_path plugin_directory; do
        [ -z "$plugin_name" ] && continue

        local is_dev="false"
        [ "$is_dev_str" = "true" ] && is_dev="true"

        local plugin_dir=""
        if [ "$is_dev" = "true" ]; then
            plugin_dir="$plugin_source_path"
        else
            plugin_dir="$PLUGINS_DIR/$plugin_name"
        fi

        # Skip if directory doesn't exist
        [ ! -d "$plugin_dir" ] && continue

        # Get plugin metadata (version, commands, categories from detection)
        # These functions are expected to be available from plugin.sh when this is called
        local plugin_version=$(detect_plugin_version "$plugin_dir")
        local plugin_cmd_count=$(count_plugin_commands "$plugin_dir")
        local plugin_categories=$(get_plugin_categories "$plugin_dir")

        # Ensure cmd_count is a valid number
        if [ -z "$plugin_cmd_count" ] || ! [[ "$plugin_cmd_count" =~ ^[0-9]+$ ]]; then
            plugin_cmd_count=0
        fi

        # Build plugin object based on available metadata
        if [ -n "$plugin_categories" ] && [ "$is_dev" = "true" ] && [ -n "$plugin_directory" ]; then
            json_data=$(echo "$json_data" | jq \
                --arg name "$plugin_name" \
                --arg version "$plugin_version" \
                --argjson commands "$plugin_cmd_count" \
                --arg cats "$plugin_categories" \
                --arg dir "$plugin_directory" \
                '.plugins += [{name: $name, version: $version, commands: $commands, categories: $cats, directory: $dir, dev: true}]')
        elif [ -n "$plugin_categories" ] && [ "$is_dev" = "true" ]; then
            json_data=$(echo "$json_data" | jq \
                --arg name "$plugin_name" \
                --arg version "$plugin_version" \
                --argjson commands "$plugin_cmd_count" \
                --arg cats "$plugin_categories" \
                '.plugins += [{name: $name, version: $version, commands: $commands, categories: $cats, dev: true}]')
        elif [ -n "$plugin_categories" ] && [ -n "$plugin_directory" ]; then
            json_data=$(echo "$json_data" | jq \
                --arg name "$plugin_name" \
                --arg version "$plugin_version" \
                --argjson commands "$plugin_cmd_count" \
                --arg cats "$plugin_categories" \
                --arg dir "$plugin_directory" \
                '.plugins += [{name: $name, version: $version, commands: $commands, categories: $cats, directory: $dir}]')
        elif [ -n "$plugin_categories" ]; then
            json_data=$(echo "$json_data" | jq \
                --arg name "$plugin_name" \
                --arg version "$plugin_version" \
                --argjson commands "$plugin_cmd_count" \
                --arg cats "$plugin_categories" \
                '.plugins += [{name: $name, version: $version, commands: $commands, categories: $cats}]')
        elif [ "$is_dev" = "true" ] && [ -n "$plugin_directory" ]; then
            json_data=$(echo "$json_data" | jq \
                --arg name "$plugin_name" \
                --arg version "$plugin_version" \
                --argjson commands "$plugin_cmd_count" \
                --arg dir "$plugin_directory" \
                '.plugins += [{name: $name, version: $version, commands: $commands, directory: $dir, dev: true}]')
        elif [ "$is_dev" = "true" ]; then
            json_data=$(echo "$json_data" | jq \
                --arg name "$plugin_name" \
                --arg version "$plugin_version" \
                --argjson commands "$plugin_cmd_count" \
                '.plugins += [{name: $name, version: $version, commands: $commands, dev: true}]')
        elif [ -n "$plugin_directory" ]; then
            json_data=$(echo "$json_data" | jq \
                --arg name "$plugin_name" \
                --arg version "$plugin_version" \
                --argjson commands "$plugin_cmd_count" \
                --arg dir "$plugin_directory" \
                '.plugins += [{name: $name, version: $version, commands: $commands, directory: $dir}]')
        else
            json_data=$(echo "$json_data" | jq \
                --arg name "$plugin_name" \
                --arg version "$plugin_version" \
                --argjson commands "$plugin_cmd_count" \
                '.plugins += [{name: $name, version: $version, commands: $commands}]')
        fi
    done <<< "$all_plugins"

    echo "$json_data"
}

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
