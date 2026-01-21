#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ============================================================
# Category Execution Functions for SUSA CLI
# ============================================================
# Functions for validating and executing categories

# Resolve category path from arguments
# Returns: marker (for entrypoint) or category, then remaining args
# Note: Uses EXEC_ENTRYPOINT_MARKER constant from core/susa
resolve_category_path() {
    local category="$1"
    shift
    local remaining_args=("$@")

    # Check if there are more arguments that could be subcategories
    while [ ${#remaining_args[@]} -gt 0 ]; do
        local next_arg="${remaining_args[0]}"

        # If it's help, show help for current category
        if [ "$next_arg" = "help" ]; then
            display_help
            exit 0
        fi

        # Try to see if it's a subcategory
        local subcategories=$(get_category_subcategories "$category")
        if echo "$subcategories" | grep -q "^${next_arg}$"; then
            # It is a subcategory, add to path
            category="$category/$next_arg"
            remaining_args=("${remaining_args[@]:1}")
        else
            # Not a subcategory - check if it's an option (starts with -)
            if [[ "$next_arg" =~ ^- ]]; then
                # It's an option - check if category has a script to handle it
                if category_has_entrypoint "$category"; then
                    # Return special marker to indicate entrypoint execution
                    echo "$EXEC_ENTRYPOINT_MARKER"
                    echo "$category"
                    printf '%s\n' "${remaining_args[@]}"
                    return 0
                fi
            fi

            # Check if it looks like a command (not an option and category has commands)
            if ! category_has_entrypoint "$category"; then
                # Not a subcategory and no entrypoint, must be a command
                break
            fi

            # Category has entrypoint but arg doesn't start with -
            # Could be a command or argument to entrypoint
            # If command exists, treat as command; otherwise check validity
            local commands=$(get_category_commands "$category" "$(get_simple_os)")
            if echo "$commands" | grep -q "^${next_arg}$"; then
                # It's a command
                break
            fi

            # Check if it's a valid subcategory
            local all_subcats=$(get_category_subcategories "$category")
            if echo "$all_subcats" | grep -q "^${next_arg}$"; then
                # It's a subcategory but we already checked above, shouldn't reach here
                break
            fi

            # Not a command or subcategory - show error with suggestion
            log_error "Comando ou subcategoria '$next_arg' não encontrado em '$category'"
            log_output ""

            # Try to find similar command AND subcategory, show the best match
            local similar_cmd=$(find_similar_command "$category" "$next_arg" 2> /dev/null)
            local similar_subcat=$(find_similar_subcategory "$category" "$next_arg" 2> /dev/null)

            # If both found, compare similarities to pick the best
            if [ -n "$similar_cmd" ] && [ -n "$similar_subcat" ]; then
                local cmd_score=$(calculate_similarity "$next_arg" "$similar_cmd")
                local subcat_score=$(calculate_similarity "$next_arg" "$similar_subcat")

                # Add bonuses
                if [[ "${next_arg:0:1}" == "${similar_cmd:0:1}" ]]; then
                    cmd_score=$((cmd_score + 10))
                fi
                if [[ "${next_arg:0:3}" == "${similar_cmd:0:3}" ]]; then
                    cmd_score=$((cmd_score + 30))
                fi

                if [[ "${next_arg:0:1}" == "${similar_subcat:0:1}" ]]; then
                    subcat_score=$((subcat_score + 10))
                fi
                if [[ "${next_arg:0:3}" == "${similar_subcat:0:3}" ]]; then
                    subcat_score=$((subcat_score + 30))
                fi

                # Show the better match
                if [ $subcat_score -gt $cmd_score ]; then
                    show_similarity_suggestion "subcategory" "$next_arg" "$similar_subcat"
                else
                    show_similarity_suggestion "command" "$next_arg" "$similar_cmd"
                fi
            elif [ -n "$similar_cmd" ]; then
                show_similarity_suggestion "command" "$next_arg" "$similar_cmd"
            elif [ -n "$similar_subcat" ]; then
                show_similarity_suggestion "subcategory" "$next_arg" "$similar_subcat"
            fi
            exit 1
        fi
    done

    # After resolving full category path, check if it has an entrypoint
    # This handles cases like "susa setup dbeaver" where dbeaver is a subcategory with entrypoint
    if [ ${#remaining_args[@]} -eq 0 ] && category_has_entrypoint "$category"; then
        # Return special marker to indicate entrypoint execution
        echo "$EXEC_ENTRYPOINT_MARKER"
        echo "$category"
        return 0
    fi

    # Return category and remaining args (space-separated)
    echo "$category"
    printf '%s\n' "${remaining_args[@]}"
}

# Execute category entrypoint with arguments
execute_category_entrypoint() {
    local category="$1"
    shift
    local entrypoint_args=("$@")

    # Check if --help was requested
    for arg in "${entrypoint_args[@]}"; do
        if [ "$arg" = "--help" ] || [ "$arg" = "-h" ]; then
            initialize_command_context "$category" "" "${entrypoint_args[@]}"
            display_help
            exit 0
        fi
    done

    # Initialize context for category with entrypoint
    initialize_command_context "$category" "" "${entrypoint_args[@]}"

    # If no args, show category help instead of executing entrypoint
    if [ ${#entrypoint_args[@]} -eq 0 ]; then
        display_help
        exit 0
    fi

    # Execute category script with args
    local script_path=$(get_category_entrypoint_path "$category")
    if [ -n "$script_path" ] && [ -f "$script_path" ]; then
        (
            set -- "${entrypoint_args[@]}"
            source "$script_path" "$@"
        )
        exit $?
    fi

    log_error "Entrypoint não encontrado para categoria: $category"
    exit 1
}

# Display category (with or without entrypoint)
display_category() {
    local category="$1"

    # Check if category has entrypoint
    if category_has_entrypoint "$category"; then
        initialize_command_context "$category" ""

        local script_path=$(get_category_entrypoint_path "$category")
        if [ -n "$script_path" ] && [ -f "$script_path" ]; then
            # Try to execute custom show_help from script
            if [ -f "$script_path" ] && grep -q "^show_help()" "$script_path" 2> /dev/null; then
                (
                    export CORE_DIR LIB_DIR CLI_DIR SUSA_SHOW_HELP=1
                    source "$script_path" 2> /dev/null || true
                    if declare -f show_help > /dev/null 2>&1; then
                        show_help
                        exit 0
                    fi
                ) && exit 0
            fi

            # No custom show_help, execute entrypoint normally
            (source "$script_path")
            exit $?
        fi

        log_error "Entrypoint não encontrado para categoria: $category"
        exit 1
    fi

    # No entrypoint - list category commands
    initialize_command_context "$category" ""
    display_help
    exit 0
}
