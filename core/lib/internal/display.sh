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

# List available commands and subcategories for a given category
display_category_help() {
    local category="$1"
    local categories=$(get_all_categories "$GLOBAL_CONFIG_FILE")

    # Validate category exists in lock file (cache)
    # No need to check physical directories - lock file is source of truth
    local category_exists=false

    # Check if it's a top-level category
    if echo "$categories" | grep -q "^${category}$"; then
        category_exists=true
    else
        # Check if any command belongs to this category (including subcategories)
        local category_commands=$(cache_query ".commands[] | select(.category == \"$category\" or (.category | startswith(\"$category/\"))) | .name" 2> /dev/null | head -1)
        if [ -n "$category_commands" ]; then
            category_exists=true
        fi
    fi

    if [ "$category_exists" = false ]; then
        log_error "Categoria '$category' não encontrada"
        return 1
    fi

    local category_desc=$(get_category_info "$GLOBAL_CONFIG_FILE" "$category" "description")
    local current_os=$(get_simple_os)
    local commands=$(get_category_commands "$category" "$current_os")
    local subcategories=$(get_category_subcategories "$category")

    log_output "$category_desc"
    log_output ""
    show_usage "$category"
    log_output ""

    # Print subcategories first
    print_subcategories "$category" "$subcategories"

    # Add spacing between subcategories and commands if both exist
    if [ -n "$subcategories" ] && [ -n "$commands" ]; then
        log_output ""
    fi

    # List commands
    if [ -n "$commands" ]; then
        log_output "${LIGHT_GREEN}Comandos:${NC}"

        # List commands without a group
        list_ungrouped_commands "$category" "$commands" "$current_os" || true
        local has_ungrouped=$?

        # List grouped commands
        local groups=$(get_category_groups "$GLOBAL_CONFIG_FILE" "$category" "$current_os")
        list_grouped_commands "$category" "$commands" "$current_os" "$groups" || true
        local has_grouped=$?

        # Show message if no compatible commands found
        if [ $has_ungrouped -ne 0 ] && [ $has_grouped -ne 0 ] && [ -z "$subcategories" ]; then
            log_output "  ${GRAY}Nenhum comando ou subcategoria disponível${NC}"
        fi
    fi

    # If category has entrypoint, execute show_complement_help if it exists
    if category_has_entrypoint "$category"; then
        local script_path=$(get_category_entrypoint_path "$category")
        if [ -n "$script_path" ] && [ -f "$script_path" ]; then
            # Check if show_complement_help function exists in the script
            if grep -q "^show_complement_help()" "$script_path" 2> /dev/null; then
                # Execute show_complement_help from the category script
                # Use a special environment variable to prevent main from running
                (
                    export CORE_DIR LIB_DIR CLI_DIR
                    export SUSA_SKIP_MAIN=1
                    source "$script_path" 2> /dev/null || true
                    if declare -F show_complement_help > /dev/null 2>&1; then
                        show_complement_help
                    fi
                ) || true
            fi
        fi
    fi
}
