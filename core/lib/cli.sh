#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Get the lib directory
source "$LIB_DIR/color.sh"
source "$LIB_DIR/internal/config.sh"

# --- CLI Helper Functions ---

# Builds the command path based on the script directory
# Example: commands/self/plugin/add -> self plugin add
build_command_path() {
    # Use BASH_SOURCE to walk up the call stack and find the main.sh script
    local i=1
    local script_path=""

    # Walk up the call stack to find a main.sh file
    while [ -n "${BASH_SOURCE[$i]:-}" ]; do
        if [[ "${BASH_SOURCE[$i]}" == */main.sh ]]; then
            script_path="${BASH_SOURCE[$i]}"
            break
        fi
        ((i++))
    done

    # If no script path found, return empty
    [ -z "$script_path" ] && return 0

    local script_dir="$(cd "$(dirname "$script_path")" && pwd)"

    # Remove the prefix up to /commands/
    local relative_path="${script_dir#*commands/}"

    # If it didn't change, try removing /plugins/
    if [ "$relative_path" = "$script_dir" ]; then
        relative_path="${script_dir#*plugins/*/}"
    fi

    # Convert / to space
    echo "$relative_path" | tr '/' ' '
}

# Gets the config file path for the calling script
get_command_config_file() {
    # Use BASH_SOURCE to walk up the call stack and find the main.sh script
    local i=1
    local script_path=""

    # Walk up the call stack to find a main.sh file
    while [ -n "${BASH_SOURCE[$i]:-}" ]; do
        if [[ "${BASH_SOURCE[$i]}" == */main.sh ]]; then
            script_path="${BASH_SOURCE[$i]}"
            break
        fi
        ((i++))
    done

    if [ -z "$script_path" ]; then
        return 1
    fi

    local script_dir="$(cd "$(dirname "$script_path")" && pwd)"
    echo "$script_dir/command.json"
}

# Displays the command usage information with customizable arguments
# Usage:
#   show_usage
#   show_usage "<file> <destination>"
#   show_usage --no-options
#   show_usage "$category"  # For category help
show_usage() {
    local cli_name="susa"
    local command_path=""
    local show_options=true
    local custom_args=""
    local is_category_param=false

    # Check if first parameter is a category path (contains / or is a known category)
    if [ $# -gt 0 ] && [[ ! "$1" =~ ^- ]] && [[ "$1" != "<"* ]]; then
        # This might be a category parameter from display_help
        is_category_param=true
        command_path="$1"
        shift
    else
        # Try to get from context first
        local type=$(context_get "command.type" 2> /dev/null || echo "")
        local full_category=$(context_get "command.full_category" 2> /dev/null || echo "")
        local command_name=$(context_get "command.current" 2> /dev/null || echo "")

        if [ "$type" = "category" ]; then
            # For categories, use full_category path with spaces instead of /
            command_path="${full_category//\// }"
        elif [ "$type" = "command" ]; then
            # For commands, build the full path
            if [[ "$full_category" == *"/"* ]]; then
                # Has subcategory (e.g., setup/dbeaver)
                command_path="${full_category//\// } $command_name"
            else
                # Simple category (e.g., setup)
                command_path="$full_category $command_name"
            fi
        else
            # Fallback to old behavior
            command_path=$(build_command_path)
        fi
    fi

    # Parse remaining arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --no-options)
                show_options=false
                shift
                ;;
            *)
                custom_args="$custom_args $1"
                shift
                ;;
        esac
    done

    # Trim leading space from custom_args
    custom_args="${custom_args# }"

    # If no custom arguments and show_options is true, use [opções]
    if [ -z "$custom_args" ] && [ "$show_options" = true ]; then
        custom_args="[opções]"
    fi

    # Build usage string
    local usage_string="${LIGHT_GREEN}Uso:${NC} ${LIGHT_CYAN}${cli_name}${NC}"

    # Add command path if available
    if [ -n "$command_path" ]; then
        usage_string="$usage_string ${CYAN}${command_path}${NC}"
    else
        usage_string="$usage_string ${CYAN}<comando>${NC}"
    fi

    # Add custom args if available
    if [ -n "$custom_args" ]; then
        usage_string="$usage_string ${GRAY}${custom_args}${NC}"
    fi

    echo -e "$usage_string"
}

# Get and display the command description from command.json
# The file command.json must have a "description" field.
show_description() {
    # Try to get from context first
    local full_category=$(context_get "command.full_category" 2> /dev/null || echo "")
    local command_name=$(context_get "command.current" 2> /dev/null || echo "")
    local type=$(context_get "command.type" 2> /dev/null || echo "")

    local cmd_desc=""

    if [ "$type" = "command" ] && [ -n "$full_category" ] && [ -n "$command_name" ]; then
        # Get description from lock file using category and command name
        cmd_desc=$(get_command_info "$GLOBAL_CONFIG_FILE" "$full_category" "$command_name" "description" 2> /dev/null || echo "")
    fi

    if [ -n "$cmd_desc" ]; then
        echo -e "$cmd_desc"
    fi
}
