#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

# Source libs
source "$LIB_DIR/internal/registry.sh"
source "$LIB_DIR/internal/plugin.sh"
source "$LIB_DIR/table.sh"

# Help function
show_complement_help() {
    log_output "${LIGHT_GREEN}Opções adicionais:${NC}"
    log_output "  --detail <plugin> Exibe detalhes completos de um plugin específico"
    log_output ""
    log_output "${LIGHT_GREEN}Descrição:${NC}"
    log_output "  Lista todos os plugins instalados no Susa CLI,"
    log_output "  incluindo origem, versão, comandos e categorias."
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa self plugin list                    # Lista todos os plugins"
    log_output "  susa self plugin list --detail my-plugin # Detalhes de um plugin"
    log_output "  susa self plugin list --help             # Exibe esta ajuda"
}

# Show detailed information about a specific plugin
show_plugin_detail() {
    local plugin_name="$1"
    local registry_file="$2"

    if ! registry_plugin_exists "$registry_file" "$plugin_name"; then
        log_error "Plugin '$plugin_name' não encontrado"
        log_output ""
        log_output "Use ${LIGHT_CYAN}susa self plugin list${NC} para ver plugins instalados"
        return 1
    fi

    local source_url=$(registry_get_plugin_info "$registry_file" "$plugin_name" "source")
    local version=$(registry_get_plugin_info "$registry_file" "$plugin_name" "version")
    local installedAt=$(registry_get_plugin_info "$registry_file" "$plugin_name" "installedAt")
    local is_dev="false"
    if registry_is_dev_plugin "$registry_file" "$plugin_name"; then
        is_dev="true"
    fi
    local cmd_count=$(registry_get_plugin_info "$registry_file" "$plugin_name" "commands")
    local categories=$(registry_get_plugin_info "$registry_file" "$plugin_name" "categories")

    # Get description
    local description=""
    if [ -d "$PLUGINS_DIR/$plugin_name" ]; then
        description=$(get_plugin_description "$PLUGINS_DIR/$plugin_name")
    elif [ "$is_dev" = "true" ] && [ -d "$source_url" ]; then
        description=$(get_plugin_description "$source_url")
    fi

    # Display header
    if [ "$is_dev" = "true" ]; then
        log_output "${BOLD}${LIGHT_CYAN}📦 $plugin_name ${MAGENTA}[DEV]${NC}"
    else
        log_output "${BOLD}${LIGHT_CYAN}📦 $plugin_name${NC}"
    fi
    log_output ""

    # Display information
    [ -n "$description" ] && log_output "${BOLD}Descrição:${NC} $description"
    log_output "${BOLD}Versão:${NC} ${version:-N/A}"
    log_output "${BOLD}Origem:${NC} $source_url"
    log_output "${BOLD}Tipo:${NC} $([ "$is_dev" = "true" ] && echo "Local (Desenvolvimento)" || echo "Remoto")"
    log_output "${BOLD}Comandos:${NC} ${cmd_count:-0}"

    if [ -n "$categories" ] && [ "$categories" != "N/A" ]; then
        log_output "${BOLD}Categorias:${NC} $categories"
    fi

    [ -n "$installedAt" ] && log_output "${BOLD}Instalado em:${NC} $installedAt"
}

# List all plugins function
list_all_plugins() {
    local REGISTRY_FILE="$1"

    log_output "${BOLD}Plugins Instalados${NC}"
    log_output ""

    if [ ! -f "$REGISTRY_FILE" ]; then
        log_info "Nenhum plugin instalado"
        log_output ""
        log_output "Para instalar plugins, use: ${LIGHT_CYAN}susa self plugin add <url>${NC}"
        return 0
    fi

    # Read plugins from registry using registry functions
    local plugin_count=$(registry_count_plugins "$REGISTRY_FILE")
    log_debug "Total de plugins no registry: $plugin_count"

    if [ "$plugin_count" -eq 0 ]; then
        log_info "Nenhum plugin instalado"
        log_output ""
        log_output "Para instalar plugins, use: ${LIGHT_CYAN}susa self plugin add <url>${NC}"
        return 0
    fi

    # Initialize table
    table_init
    table_add_header "Nome" "Versão" "Comandos" "Categorias" "Origem"

    # Get all plugin names from registry
    local plugin_names=$(registry_get_all_plugin_names "$REGISTRY_FILE")

    # Iterate through plugins
    while IFS= read -r plugin_name; do
        [ -z "$plugin_name" ] && continue

        local source_url=$(registry_get_plugin_info "$REGISTRY_FILE" "$plugin_name" "source")
        local version=$(registry_get_plugin_info "$REGISTRY_FILE" "$plugin_name" "version")
        local is_dev="false"
        if registry_is_dev_plugin "$REGISTRY_FILE" "$plugin_name"; then
            is_dev="true"
        fi
        local cmd_count=$(registry_get_plugin_info "$REGISTRY_FILE" "$plugin_name" "commands")
        local categories=$(registry_get_plugin_info "$REGISTRY_FILE" "$plugin_name" "categories")

        # Skip if plugin name is empty
        if [ -z "$plugin_name" ]; then
            continue
        fi

        # If commands not in registry, count from directory (fallback)
        if [ -z "$cmd_count" ]; then
            if [ -d "$PLUGINS_DIR/$plugin_name" ]; then
                cmd_count=$(find "$PLUGINS_DIR/$plugin_name" -name "command.json" -type f | wc -l)
            else
                cmd_count=0
            fi
        fi

        # Count categories
        local category_count=0
        if [ -z "$categories" ] || [ "$categories" = "N/A" ]; then
            if [ -d "$PLUGINS_DIR/$plugin_name" ]; then
                categories=$(get_plugin_categories "$PLUGINS_DIR/$plugin_name")
            elif [ "$is_dev" = "true" ] && [ -d "$source_url" ]; then
                categories=$(get_plugin_categories "$source_url")
            fi
        fi

        if [ -n "$categories" ] && [ "$categories" != "N/A" ]; then
            category_count=$(echo "$categories" | tr ',' '\n' | wc -l | tr -d ' ')
        fi

        # Format plugin name with dev indicator
        local name_display
        if [ "$is_dev" = "true" ]; then
            name_display="${LIGHT_CYAN}${plugin_name}${NC} ${MAGENTA}[DEV]${NC}"
        else
            name_display="${LIGHT_CYAN}${plugin_name}${NC}"
        fi

        # Format origin (Local or Remote)
        local origin_display="$([ "$is_dev" = "true" ] && echo "Local" || echo "Remoto")"

        # Format version
        local version_display="${version:-N/A}"

        # Add row to table
        table_add_row "$name_display" "$version_display" "$cmd_count" "$category_count" "$origin_display"

    done <<< "$plugin_names"

    # Render table
    table_render

    # Show summary
    log_output ""
    log_output "${GREEN}Total: $plugin_count plugin(s)${NC}"
}

# Main function
main() {
    local DETAIL_PLUGIN=""
    local REGISTRY_FILE="$PLUGINS_DIR/registry.json"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --detail)
                if [ -z "${2:-}" ]; then
                    log_error "O argumento --detail requer um nome de plugin"
                    exit 1
                fi
                DETAIL_PLUGIN="$2"
                shift 2
                ;;
            *)
                log_error "Argumento inválido: $1"
                log_output ""
                show_help
                exit 1
                ;;
        esac
    done

    # Execute main or detail function
    if [ -n "$DETAIL_PLUGIN" ]; then
        if [ ! -f "$REGISTRY_FILE" ]; then
            log_error "Nenhum plugin instalado"
            exit 1
        fi
        show_plugin_detail "$DETAIL_PLUGIN" "$REGISTRY_FILE"
    else
        list_all_plugins "$REGISTRY_FILE"
    fi
}

# Execute main only if not showing help
if [ "${SUSA_SHOW_HELP:-}" != "1" ]; then
    main "$@"
fi
