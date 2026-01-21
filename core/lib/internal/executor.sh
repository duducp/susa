#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ============================================================
# Command Execution Functions for SUSA CLI
# ============================================================
# Functions for validating and executing commands

# Initialize command context with structure details
# Args: category command args...
initialize_command_context() {
    local full_category="$1"
    local command="$2"
    shift 2
    local all_args=("$@")

    # Initialize context
    context_init

    # Parse command structure
    local category="$full_category"
    local parent=""
    local current="$command"
    local action=""
    local args=()
    local type="command" # Default to command

    # Extract category structure
    if [[ "$full_category" == *"/"* ]]; then
        # Has subcategory path
        if [ -n "$command" ]; then
            # Has command - parent is the last part of category path
            # Ex: "setup/dbeaver" + "install" -> category="setup", parent="dbeaver", command="install", current="install"
            parent="${full_category##*/}"
            category="${full_category%/*}"
            type="command"
        else
            # No command - it's a category with entrypoint
            # Ex: "setup/dbeaver" (no command) -> category="setup", parent="", full_category="setup/dbeaver"
            # Use the last part of category as the "command" name for context
            current="${full_category##*/}"
            category="${full_category%/*}"
            type="category"
        fi
    else
        # Simple path (no /)
        if [ -z "$command" ]; then
            # No command - it's a category
            type="category"
        else
            # Has command
            type="command"
        fi
    fi

    # Build full command - reconstruct the path as user typed it
    local full_command="susa"
    if [[ "$full_category" == *"/"* ]]; then
        # Replace / with space for display (ex: self/context -> self context)
        full_command="$full_command ${full_category//\// }"
    else
        full_command="$full_command $category"
    fi

    # Add command name if not empty (for regular commands)
    if [ -n "$command" ]; then
        full_command="$full_command $command"
    fi

    # Append args if any
    for arg in "${all_args[@]}"; do
        full_command="$full_command $arg"
    done

    # Separate action from args
    # If first arg is not a flag, it's the action and the rest are args
    if [ ${#all_args[@]} -gt 0 ] && [[ ! "${all_args[0]}" =~ ^- ]]; then
        action="${all_args[0]}"
        # Args are everything after the action
        if [ ${#all_args[@]} -gt 1 ]; then
            args=("${all_args[@]:1}")
        fi
    else
        # No action, all are args (flags/options)
        args=("${all_args[@]}")
    fi

    # Get command config path
    local config_file=""
    if [ -n "$command" ]; then
        config_file=$(find_command_config "$full_category" "$command")
    fi
    local command_path=""
    if [ -n "$config_file" ]; then
        command_path=$(dirname "$config_file")
    fi

    # Save to context
    context_set "command.type" "$type"
    context_set "command.category" "$category"
    context_set "command.full_category" "$full_category"
    context_set "command.name" "$command"
    context_set "command.parent" "$parent"
    context_set "command.current" "$current"
    context_set "command.action" "$action"
    context_set "command.full" "$full_command"
    context_set "command.path" "$command_path"
    context_set "command.args" "$(printf '%s\n' "${args[@]}")"
    context_set "command.args_count" "${#args[@]}"

    # Save individual args for easy access
    for i in "${!args[@]}"; do
        context_set "command.arg.$i" "${args[$i]}"
    done

    log_debug2 "Contexto de comando inicializado: $full_command"
}

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
            # Set flag to prevent main execution
            export SUSA_SHOW_HELP=1

            # Try to source the script and show help
            # display_help will auto-detect show_help or show_complement_help if they exist
            (
                # Try to source the command script
                source "$script_path" 2> /dev/null || true
                display_help
                exit 0
            ) && exit 0 # If subshell succeeded, exit

            # If we get here, script failed to load
            # Show default help (without arguments = command help)
            log_debug "Retornando à exibição de ajuda padrão para $script_path"
            display_help
            exit 0
        fi
    done
}

# Validate command arguments
# Check for invalid combined flags like -hg
validate_command_arguments() {
    local args=("$@")

    for arg in "${args[@]}"; do
        # Skip if not a flag
        if [[ ! "$arg" =~ ^- ]]; then
            continue
        fi

        # Skip if it's a known valid pattern (long flag with value or double dash)
        if [[ "$arg" =~ ^--.*=.* ]] || [[ "$arg" == "--" ]]; then
            continue
        fi

        # Check for invalid combined short flags (more than one character after single -)
        # Valid: -h, -v, -y
        # Invalid: -hg, -abc, -vvv (unless explicitly handled by command)
        if [[ "$arg" =~ ^-[a-zA-Z]{2,}$ ]]; then
            # Check if it's a valid combined flag like -vvv for verbosity
            if [[ "$arg" =~ ^-v+$ ]]; then
                continue # -v, -vv, -vvv are valid
            fi

            log_error "Argumento inválido: '$arg'"
            log_output ""

            # Build proper command path for help suggestion
            local category=$(context_get "command.category")
            local parent=$(context_get "command.parent")
            local current=$(context_get "command.current")
            local help_cmd="susa $category"

            if [ -n "$parent" ]; then
                help_cmd="$help_cmd $parent"
            fi

            if [ -n "$current" ]; then
                help_cmd="$help_cmd $current"
            fi

            log_output "Use ${LIGHT_CYAN}$help_cmd --help${NC} para ver as opções válidas."
            exit 1
        fi
    done
}

# Execute a command with its arguments
# Note: Context should already be initialized by the caller
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

    # Validate arguments before execution
    validate_command_arguments "$@"

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

    # Export command name and category for use in scripts
    export COMMAND_NAME="$command"
    export COMMAND_CATEGORY="$category"

    source "$script_path" "$@"
}
