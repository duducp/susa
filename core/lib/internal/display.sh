#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ============================================================
# Display Functions for SUSA CLI
# ============================================================
# Functions for formatting and displaying CLI help and lists

# Display CLI logo with version
show_logo() {
    local version=$(show_number_version)
    cat << LOGO
   _____
  / ____|
 | (___  _   _ ___  __ _
  \___ \| | | / __|/ _' |
  ____) | |_| \__ \ (_| |
 |_____/ \__,_|___/\__,_| ${version}

LOGO
}

# Display global help information
show_global_help() {
    show_logo

    local description=$(get_config_field "$GLOBAL_CONFIG_FILE" "description")
    local categories=$(get_all_categories "$GLOBAL_CONFIG_FILE")

    log_output "$description"
    log_output ""
    show_usage
    log_output ""
    log_output "${LIGHT_GREEN}Comandos:${NC}"

    for cat in $categories; do
        # Skip subcategories (those containing /)
        if [[ "$cat" == *"/"* ]]; then
            continue
        fi
        local cat_desc=$(get_category_info "$GLOBAL_CONFIG_FILE" "$cat" "description")
        printf "  ${LIGHT_CYAN}%-15s${NC} %s\n" "$cat" "$cat_desc"
    done

    log_output ""
    log_output "${LIGHT_GREEN}Opções globais:${NC}"
    printf "  ${LIGHT_CYAN}%-15s${NC} %s\n" "-h, --help" "Mostra esta mensagem de ajuda"
    printf "  ${LIGHT_CYAN}%-15s${NC} %s\n" "-V, --version" "Mostra a versão do CLI"
}

# Print subcategories for a given category
print_subcategories() {
    local category="$1"
    local subcategories="$2"

    if [ -z "$subcategories" ]; then
        return 0
    fi

    log_output "${LIGHT_GREEN}Subcategories:${NC}"
    for subcat in $subcategories; do
        local subcat_desc=$(get_category_info "$GLOBAL_CONFIG_FILE" "$category/$subcat" "description")
        printf "  ${LIGHT_MAGENTA}%-15s${NC} %s\n" "$subcat" "$subcat_desc"
    done
}

# Format and print a command with its indicators
print_command_line() {
    local category="$1"
    local cmd="$2"
    local cmd_desc="$3"

    local indicators=""

    # Add installed indicator for setup commands
    if [ "$category" = "setup" ]; then
        # Source installations library if not already loaded
        if ! declare -f is_installed &> /dev/null; then
            source "$LIB_DIR/internal/installations.sh" 2> /dev/null || true
        fi

        # Check if software is installed
        if declare -f is_installed &> /dev/null && is_installed "$cmd" 2> /dev/null; then
            indicators="${indicators} ${GREEN}✓${NC}"
        fi
    fi

    # Add plugin indicator if necessary
    if is_plugin_command "$category" "$cmd"; then
        indicators="${indicators} ${GRAY}[plugin]${NC}"
    fi

    # Add dev indicator if necessary
    if is_dev_plugin_command "$category" "$cmd"; then
        indicators="${indicators} ${MAGENTA}[dev]${NC}"
    fi

    # Add sudo indicator if necessary
    if requires_sudo "$GLOBAL_CONFIG_FILE" "$category" "$cmd"; then
        indicators="${indicators} ${YELLOW}[sudo]${NC}"
    fi

    printf "  ${LIGHT_CYAN}%-15s${NC} %s%b\n" "$cmd" "$cmd_desc" "$indicators"
}

# List commands without a group
list_ungrouped_commands() {
    local category="$1"
    local commands="$2"
    local current_os="$3"
    local has_compatible_commands=false

    for cmd in $commands; do
        # Check OS compatibility
        if ! is_command_compatible "$GLOBAL_CONFIG_FILE" "$category" "$cmd" "$current_os"; then
            continue
        fi

        # Skip commands that belong to a group
        local cmd_group=$(get_command_group "$GLOBAL_CONFIG_FILE" "$category" "$cmd")
        if [ -n "$cmd_group" ]; then
            continue
        fi

        has_compatible_commands=true
        local cmd_desc=$(get_command_info "$GLOBAL_CONFIG_FILE" "$category" "$cmd" "description")
        print_command_line "$category" "$cmd" "$cmd_desc"
    done

    [ "$has_compatible_commands" = "true" ] && return 0 || return 1
}

# List grouped commands
list_grouped_commands() {
    local category="$1"
    local commands="$2"
    local current_os="$3"
    local groups="$4"
    local has_compatible_commands=false

    if [ -z "$groups" ]; then
        return 1
    fi

    while IFS= read -r group; do
        [ -z "$group" ] && continue

        log_output ""
        log_output " ${LIGHT_GRAY}$group${NC}"

        for cmd in $commands; do
            # Check OS compatibility
            if ! is_command_compatible "$GLOBAL_CONFIG_FILE" "$category" "$cmd" "$current_os"; then
                continue
            fi

            local cmd_group=$(get_command_group "$GLOBAL_CONFIG_FILE" "$category" "$cmd")

            # List only commands from this group
            if [ "$cmd_group" = "$group" ]; then
                has_compatible_commands=true
                local cmd_desc=$(get_command_info "$GLOBAL_CONFIG_FILE" "$category" "$cmd" "description")
                print_command_line "$category" "$cmd" "$cmd_desc"
            fi
        done
    done <<< "$groups"

    [ "$has_compatible_commands" = "true" ] && return 0 || return 1
}

# Validate if category exists in lock file
_validate_category_exists() {
    local full_category="$1"
    local categories=$(get_all_categories "$GLOBAL_CONFIG_FILE")

    # Check if it's a top-level category
    if echo "$categories" | grep -q "^${full_category}$"; then
        return 0
    fi

    # Check if any command belongs to this category (including subcategories)
    local category_commands=$(cache_query ".commands[] | select(.category == \"$full_category\" or (.category | startswith(\"$full_category/\"))) | .name" 2> /dev/null | head -1)
    if [ -n "$category_commands" ]; then
        return 0
    fi

    return 1
}

# Display help for commands
_display_command_help() {
    # Priority 1: custom show_help (complete replacement)
    if declare -f show_help > /dev/null 2>&1; then
        show_help
        return 0
    fi

    # Priority 2: Standard command help + show_complement_help
    show_description
    log_output ""
    show_usage
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"

    # Add custom complement if available
    if declare -f show_complement_help > /dev/null 2>&1; then
        log_output ""
        show_complement_help
    fi
}

# Display category commands (with or without grouping)
_display_category_commands() {
    local full_category="$1"
    local commands="$2"
    local current_os="$3"
    local subcategories="$4"

    if [ -z "$commands" ]; then
        return 0
    fi

    log_output "${LIGHT_GREEN}Comandos:${NC}"

    if [ "${SUSA_GROUP:-0}" = "1" ]; then
        # List ungrouped commands
        list_ungrouped_commands "$full_category" "$commands" "$current_os" || true
        local has_ungrouped=$?

        # List grouped commands
        local groups=$(get_category_groups "$GLOBAL_CONFIG_FILE" "$full_category" "$current_os")
        list_grouped_commands "$full_category" "$commands" "$current_os" "$groups" || true
        local has_grouped=$?

        # Show message if no compatible commands found
        if [ $has_ungrouped -ne 0 ] && [ $has_grouped -ne 0 ] && [ -z "$subcategories" ]; then
            log_output "  ${GRAY}Nenhum comando ou subcategoria disponível${NC}"
        fi
    else
        # List all commands without grouping (default)
        local has_compatible=false
        for cmd in $commands; do
            if ! is_command_compatible "$GLOBAL_CONFIG_FILE" "$full_category" "$cmd" "$current_os"; then
                continue
            fi

            has_compatible=true
            local cmd_desc=$(get_command_info "$GLOBAL_CONFIG_FILE" "$full_category" "$cmd" "description")
            print_command_line "$full_category" "$cmd" "$cmd_desc"
        done

        if [ "$has_compatible" = false ] && [ -z "$subcategories" ]; then
            log_output "  ${GRAY}Nenhum comando ou subcategoria disponível${NC}"
        fi
    fi
}

# Execute category's show_complement_help if available
_execute_category_complement_help() {
    local full_category="$1"

    if ! category_has_entrypoint "$full_category"; then
        return 0
    fi

    local script_path=$(get_category_entrypoint_path "$full_category")
    if [ -z "$script_path" ] || [ ! -f "$script_path" ]; then
        return 0
    fi

    # Check if show_complement_help exists in the script
    if ! grep -q "^show_complement_help()" "$script_path" 2> /dev/null; then
        return 0
    fi

    # Execute show_complement_help
    (
        export CORE_DIR LIB_DIR CLI_DIR SUSA_SHOW_HELP=1
        source "$script_path" 2> /dev/null || true
        if declare -F show_complement_help > /dev/null 2>&1; then
            log_output ""
            show_complement_help
        fi
    ) || true
}

# Display help for categories
_display_category_help() {
    local full_category="$1"

    # Validate category exists
    if ! _validate_category_exists "$full_category"; then
        log_error "Categoria '$full_category' não encontrada"
        return 1
    fi

    # Get category info
    local category_desc=$(get_category_info "$GLOBAL_CONFIG_FILE" "$full_category" "description")
    local current_os=$(get_simple_os)
    local commands=$(get_category_commands "$full_category" "$current_os")
    local subcategories=$(get_category_subcategories "$full_category")

    # Display header
    log_output "$category_desc"
    log_output ""
    show_usage "$full_category"
    log_output ""

    # Display subcategories
    print_subcategories "$full_category" "$subcategories"

    # Add spacing between subcategories and commands
    if [ -n "$subcategories" ] && [ -n "$commands" ]; then
        log_output ""
    fi

    # Display commands
    _display_category_commands "$full_category" "$commands" "$current_os" "$subcategories"

    # Execute category's show_complement_help if available
    _execute_category_complement_help "$full_category"
}

# Display help for category or command
# Uses context to determine type and path - no parameters needed
display_help() {
    local type=$(context_get "command.type" 2> /dev/null || echo "command")
    local full_category=$(context_get "command.full_category" 2> /dev/null || echo "")

    if [ "$type" = "command" ]; then
        _display_command_help
    else
        _display_category_help "$full_category"
    fi
}
