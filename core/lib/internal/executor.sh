#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ============================================================
# Command Execution Functions for SUSA CLI
# ============================================================
# Functions for validating and executing commands

# Validate command exists and is compatible with current OS
validate_command() {
    local category="$1"
    local command="$2"
    local current_os="$3"

    # Find command config
    local config_file=$(find_command_config "$category" "$command")

    if [ -z "$config_file" ]; then
        log_error "Comando '$command' não encontrado na categoria '$category'"
        exit 1
    fi

    # Check OS compatibility
    if ! is_command_compatible "$GLOBAL_CONFIG_FILE" "$category" "$command" "$current_os"; then
        log_error "Comando '$command' não é compatível com o sistema operacional atual ($current_os)"
        exit 1
    fi

    echo "$config_file"
}

# Check if help was requested for the command
check_and_show_command_help() {
    local script_path="$1"
    shift

    for arg in "$@"; do
        if [ "$arg" = "--help" ] || [ "$arg" = "-h" ]; then
            # Check if show_help function exists without executing the script
            if grep -q "^show_help()" "$script_path" 2> /dev/null; then
                export SUSA_SHOW_HELP_CALLED=true
                source "$script_path"
                show_help
                unset SUSA_SHOW_HELP_CALLED
            fi
            exit 0
        fi
    done
}

# Execute a command with its arguments
execute_command() {
    local category="$1"
    local command="$2"
    shift 2

    local current_os=$(get_simple_os)

    # Validate command exists and is compatible
    local config_file
    config_file=$(validate_command "$category" "$command" "$current_os")
    if [ $? -ne 0 ] || [ -z "$config_file" ]; then
        exit 1
    fi

    # Get entrypoint name and build path
    local script_name=$(get_command_info "$GLOBAL_CONFIG_FILE" "$category" "$command" "entrypoint")

    # Check if this is a plugin command (has source in lock)
    local plugin_source=""
    local plugin_directory=""
    local plugin_name=""
    if has_valid_lock_file; then
        # Use cache instead of direct jq for better performance
        plugin_source=$(cache_query ".commands[] | select(.category == \"$category\" and .name == \"$command\" and .plugin != null) | .plugin.source" 2> /dev/null | head -1)
        plugin_name=$(cache_query ".commands[] | select(.category == \"$category\" and .name == \"$command\" and .plugin != null) | .plugin.name" 2> /dev/null | head -1)

        # Get directory from the plugins array using the plugin name
        if [ -n "$plugin_name" ] && [ "$plugin_name" != "null" ]; then
            plugin_directory=$(cache_get_plugin_info "$plugin_name" "directory" 2> /dev/null)
        fi
    fi

    # Build script path - use plugin source if available
    local script_path=""
    if [ -n "$plugin_source" ] && [ "$plugin_source" != "null" ]; then
        # Plugin with source - use source from lock
        if [ -n "$plugin_directory" ] && [ "$plugin_directory" != "null" ] && [ "$plugin_directory" != "" ]; then
            # Plugin has a specific directory configured
            script_path="$plugin_source/$plugin_directory/$category/$command/$script_name"
        else
            # Plugin uses root directory
            script_path="$plugin_source/$category/$command/$script_name"
        fi
    else
        # Regular command
        local command_dir=$(dirname "$config_file")
        script_path="$command_dir/$script_name"
    fi

    if [ ! -f "$script_path" ]; then
        log_error "Script '$script_name' não encontrado em $(dirname "$script_path")/"
        exit 1
    fi

    # Check if help was requested for the command
    check_and_show_command_help "$script_path" "$@"

    # Check if sudo is required (bypass logic handled internally)
    if requires_sudo "$GLOBAL_CONFIG_FILE" "$category" "$command"; then
        # Lazy load sudo library only when needed
        if ! declare -f required_sudo &> /dev/null; then
            source "$LIB_DIR/sudo.sh"
        fi
        required_sudo "$@"
    fi

    # Load environment variables from command config
    load_command_envs "$config_file"

    # Export command name for use in scripts
    export COMMAND_NAME="$command"

    source "$script_path" "$@"
}
