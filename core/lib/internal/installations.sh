#!/usr/bin/env zsh

# ============================================================
# Installation Tracking Library
# ============================================================
# Functions to track software installations in lock file

source "$LIB_DIR/internal/json.sh"
source "$LIB_DIR/cache.sh"

# Returns the absolute path to susa.lock file
# Usage: lock_file=$(get_lock_file_path)
get_lock_file_path() {
    echo "${CLI_DIR}/susa.lock"
}

# Internal helper: Query installation data from lock file
# Args: command_name jq_selector
# Returns: selected value or empty
# Usage: _query_installation_field "docker" ".version"
_query_installation_field() {
    local command_name="$1"
    local selector="$2"
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    jq -r ".installations[] | select(.name == \"$command_name\") | $selector // empty" "$lock_file" 2> /dev/null
}

# Gets list of installed software names from cache (performance optimized)
# Returns: newline-separated list of software names marked as installed
# Usage: installations=$(get_installed_from_cache)
get_installed_from_cache() {
    cache_query '.installations[]? | select(.installed == true) | .name'
}

# Checks if software is marked as installed (cache-optimized version)
# Args: software_name
# Returns: 0 if installed, 1 otherwise
# Usage: if is_installed_cached "docker"; then ...
is_installed_cached() {
    local installation_command_name="$1"

    if [ -z "$installation_command_name" ]; then
        return 1
    fi

    # Use cache for fast lookup
    local installed=$(cache_query ".installations[]? | select(.name == \"$installation_command_name\") | .installed" 2> /dev/null)

    [ "$installed" = "true" ] && return 0
    return 1
}

# Gets version from cache (performance optimized)
# Args: software_name
# Returns: version string or empty
# Usage: version=$(get_installed_version_cached "docker")
get_installed_version_cached() {
    local software_name="$1"

    if [ -z "$software_name" ]; then
        return 1
    fi

    local version=$(cache_query ".installations[]? | select(.name == \"$software_name\") | .version // empty" 2> /dev/null)

    if [ -n "$version" ] && [ "$version" != "null" ]; then
        echo "$version"
        return 0
    fi

    return 1
}

# Internal: Marks software as installed in lock file with version and timestamp
# Args: software_name, version (optional, defaults to "unknown")
# Usage: _mark_installed_software_in_lock "docker" "24.0.5"
_mark_installed_software_in_lock() {
    local software_name="$1"
    local version="${2:-unknown}"
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        log_warning "Lock file not found. Run 'susa self lock' first."
        return 1
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Check if software already tracked
    local exists=$(jq -r ".installations[] | select(.name == \"$software_name\") | .name" "$lock_file" 2> /dev/null)

    if [ -n "$exists" ] && [ "$exists" != "null" ]; then
        # Update existing entry
        local temp_file=$(mktemp)
        jq --arg name "$software_name" --arg ver "$version" --arg ts "$timestamp" \
            '(.installations[] | select(.name == $name)) |= {name: $name, installed: true, version: $ver, installedAt: $ts}' \
            "$lock_file" > "$temp_file" && mv "$temp_file" "$lock_file"
    else
        # Add new entry
        local temp_file=$(mktemp)
        jq --arg name "$software_name" --arg ver "$version" --arg ts "$timestamp" \
            '.installations += [{name: $name, installed: true, version: $ver, installedAt: $ts}]' \
            "$lock_file" > "$temp_file" && mv "$temp_file" "$lock_file"
    fi

    return 0
}

# Internal: Updates version and timestamp for already registered software
# Args: software_name, version
# Returns: 0 if updated, 1 if not found
# Usage: _update_software_version_in_lock "docker" "24.0.6"
_update_software_version_in_lock() {
    local software_name="$1"
    local version="$2"
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Check if software is tracked
    local exists=$(jq -r ".installations[] | select(.name == \"$software_name\") | .name" "$lock_file" 2> /dev/null)

    if [ -n "$exists" ] && [ "$exists" != "null" ]; then
        local temp_file=$(mktemp)
        jq --arg name "$software_name" --arg ver "$version" --arg ts "$timestamp" \
            '(.installations[] | select(.name == $name)) |= (.version = $ver | .updatedAt = $ts)' \
            "$lock_file" > "$temp_file" && mv "$temp_file" "$lock_file"
        return 0
    fi

    return 1
}

# Smart function: registers new or updates existing software in lock file
# Args: software_name (optional, defaults to $COMMAND_NAME), version (optional, defaults to "unknown")
# Usage: register_or_update_software_in_lock "docker" "24.0.6"
register_or_update_software_in_lock() {
    local software_name="${1:-${COMMAND_NAME:-}}"
    local version="${2:-unknown}"

    if [ -z "$software_name" ]; then
        log_error "Nome do software não especificado e COMMAND_NAME não definida"
        return 1
    fi

    if is_installed "$software_name"; then
        _update_software_version_in_lock "$software_name" "$version"
    else
        _mark_installed_software_in_lock "$software_name" "$version"
    fi

    return 0
}

# Marks software as uninstalled (installed: false) and clears version
# Args: software_name (optional, defaults to $COMMAND_NAME)
# Usage: remove_software_in_lock "docker"
remove_software_in_lock() {
    local software_name="${1:-${COMMAND_NAME:-}}"

    if [ -z "$software_name" ]; then
        log_error "Nome do software não especificado e COMMAND_NAME não definida"
        return 1
    fi

    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        return 0
    fi

    # Check if software is tracked
    local exists=$(jq -r ".installations[] | select(.name == \"$software_name\") | .name" "$lock_file" 2> /dev/null)

    if [ -n "$exists" ] && [ "$exists" != "null" ]; then
        # Mark as uninstalled and clear version
        local temp_file=$(mktemp)
        jq --arg name "$software_name" \
            '(.installations[] | select(.name == $name)) |= {name: $name, installed: false, version: null} |
             (.installations[] | select(.name == $name)) |= del(.installedAt)' \
            "$lock_file" > "$temp_file" && mv "$temp_file" "$lock_file"
    fi

    return 0
}

# Checks if software is marked as installed in lock file (not system check)
# Args: software_name (optional, defaults to $COMMAND_NAME)
# Returns: 0 if installed in lock, 1 otherwise
# Usage: if is_installed "docker"; then ...
is_installed() {
    local command_name="${COMMAND_NAME:-}"
    local software_name="${1:-${command_name}}"

    if [ -z "$software_name" ]; then
        return 1
    fi

    local installed=$(_query_installation_field "$command_name" ".installed")
    [ "$installed" = "true" ] && return 0
    return 1
}

# Gets version stored in lock file (not current system version)
# Args: software_name (optional, defaults to $COMMAND_NAME)
# Returns: 0 with version string, 1 if not found
# Usage: version=$(get_installed_version "docker")
get_installed_version() {
    local command_name="${COMMAND_NAME:-}"
    local software_name="${1:-${command_name}}"

    if [ -z "$software_name" ]; then
        return 1
    fi

    local version=$(_query_installation_field "$command_name" ".version")

    if [ -n "$version" ] && [ "$version" != "null" ]; then
        echo "$version"
        return 0
    fi

    return 1
}

# Gets complete installation JSON object from lock file
# Args: software_name (optional, defaults to $COMMAND_NAME)
# Returns: 0 with JSON output, 1 if not found
# Usage: get_installation_info "docker"
get_installation_info() {
    local command_name="${COMMAND_NAME:-}"
    local software_name="${1:-${command_name}}"

    if [ -z "$command_name" ]; then
        return 1
    fi

    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    jq -r ".installations[] | select(.name == \"$command_name\")" "$lock_file" 2> /dev/null
    return 0
}

# Lists all software marked as installed in lock file
# Always syncs installations before listing
# Args: --check-updates (optional) - checks for available updates
# Displays: formatted table with software, version and optionally update info
# Returns: 0 with formatted list, 1 if lock not found
# Usage: list_installed [--check-updates]
list_installed() {
    local lock_file=$(get_lock_file_path)
    local check_updates=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --check-updates)
                check_updates=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    # Show loading message to user (without timestamp for cleaner output)
    log_output "${CYAN}⏳ Sincronizando instalações...${NC}"

    # Sync installations (hide output)
    sync_installations > /dev/null 2>&1

    # Refresh cache after sync to ensure data is up-to-date
    cache_refresh 2> /dev/null || true

    # Get installed software and format output
    local installed=$(jq -r '.installations[] | select(.installed == true) | .name' "$lock_file" 2> /dev/null)

    if [ -z "$installed" ]; then
        echo ""
        log_warning "Nenhum software instalado encontrado."
        echo ""
        return 0
    fi

    # Count total
    local total=$(echo "$installed" | wc -l | tr -d ' ')

    # Display header
    echo ""
    if [ "$check_updates" = true ]; then
        log_output "${LIGHT_GREEN}✓ Softwares instalados (${total}) - Verificando atualizações...${NC}"
    else
        log_output "${LIGHT_GREEN}✓ Softwares instalados (${total}):${NC}"
    fi
    echo ""

    # Load table library
    source "$LIB_DIR/table.sh"

    # Initialize table
    table_init

    # Add header based on mode
    if [ "$check_updates" = true ]; then
        table_add_header "Software" "Versão Atual" "Última Versão" "Status"
    else
        table_add_header "Software" "Versão"
    fi

    # Add rows for each installed software
    while IFS= read -r name; do
        [ -z "$name" ] && continue

        # Get current version from lock file
        local current_version=$(jq -r ".installations[] | select(.name == \"$name\") | .version // \"unknown\"" "$lock_file" 2> /dev/null)

        # Format software name with color
        local software_display="${LIGHT_CYAN}${name}${NC}"

        # Check for updates if requested
        if [ "$check_updates" = true ]; then
            # Get latest version
            local latest_version=$(get_latest_software_version "$name" 2> /dev/null)
            [ -z "$latest_version" ] || [ "$latest_version" = "desconhecida" ] && latest_version="N/A"

            # Normalize versions for comparison (remove 'v' prefix if present)
            local current_normalized="${current_version#v}"
            local latest_normalized="${latest_version#v}"

            # Determine update status
            local update_status=""
            if [ "$latest_version" = "N/A" ]; then
                update_status="${GRAY}-${NC}"
            elif [ "$current_version" = "unknown" ]; then
                update_status="${GRAY}-${NC}"
            elif [ "$latest_normalized" != "$current_normalized" ]; then
                update_status="${YELLOW}⚠ Atualização disponível${NC}"
            else
                update_status="${GREEN}✓ Atualizado${NC}"
            fi

            table_add_row "$software_display" "$current_version" "$latest_version" "$update_status"
        else
            table_add_row "$software_display" "$current_version"
        fi
    done <<< "$installed"

    # Render the table
    table_render

    return 0
}

# Scans commands/setup directory and lists available setup commands
# Uses cache for performance (reads from susa.lock instead of disk)
# Returns: 0 with newline-separated command names, 1 if unavailable
# Usage: get_available_setup_commands
get_available_setup_commands() {
    # Extract base command name from category (e.g., "setup/docker" -> "docker")
    # Collect all results in array, apply unique to remove duplicates, then iterate
    local commands=$(cache_query '[.commands[]? | select(.category | startswith("setup/")) | (.category | split("/") | .[1])] | unique | .[]' 2> /dev/null)

    if [ -n "$commands" ]; then
        log_debug "Comandos de setup obtidos do cache"
        echo "$commands"
        return 0
    fi

    log_error "Falha ao obter os comandos de setup do cache"
    return 1
}

# Checks if software is actually installed on system (not lock file)
# Args: software_name - name of the setup command (e.g., "docker", "vscode")
# Returns: 0 if installed, 1 if not
# Usage: if check_software_installed "docker"; then ...
check_software_installed() {
    local software_name="${1:-}"

    if [ -z "$software_name" ]; then
        log_debug "Nome do software não especificado"
        return 1
    fi

    # Construct path to the command's utils/common.sh
    local common_utils="$CLI_DIR/commands/setup/$software_name/utils/common.sh"

    # Check if utils/common.sh exists and load it (suppress readonly errors)
    if [ -f "$common_utils" ]; then
        log_debug "Carregando utils para: $software_name"

        # Source the file, suppressing readonly variable errors
        source "$common_utils" 2> /dev/null || true
    else
        log_debug "Arquivo utils/common.sh não encontrado para: $software_name"
        return 1
    fi

    # Now check if check_installation function exists and call it
    if declare -f check_installation > /dev/null 2>&1; then
        log_debug "Verificando se $software_name está instalado via check_installation()"

        check_installation &> /dev/null
        local exit_code=$?

        if [ $exit_code -eq 0 ]; then
            log_debug "Software '$software_name' está instalado (exit code: $exit_code)"
            return 0
        fi

        log_debug "Software '$software_name' não está instalado (exit code: $exit_code)"
        return 1
    else
        log_debug "Função check_installation() não implementada em $software_name"
        return 1
    fi
}

# Gets current version from system by calling get_current_version() from command context
# This function should only be called within a command's execution context (e.g., --info flag)
# Args: software_name (optional) - name of the setup command
# Returns: version string or "N/A"
get_current_software_version() {
    local software_name="${1:-}"

    # If no software name provided, try to get from context
    if [ -z "$software_name" ]; then
        software_name=$(context_get "command.current" 2> /dev/null || echo "")
    fi

    # If we have a software name, try to load its utils and get version
    if [ -n "$software_name" ]; then
        local common_utils="$CLI_DIR/commands/setup/$software_name/utils/common.sh"

        if [ -f "$common_utils" ]; then
            log_debug "Obtendo versão atual de $software_name"

            # Source the file (suppress readonly errors)
            source "$common_utils" 2> /dev/null || true

            # Now call the function if it exists
            if declare -f get_current_version > /dev/null 2>&1; then
                local version=$(get_current_version 2> /dev/null)
                if [ -n "$version" ] && [ "$version" != "desconhecida" ]; then
                    echo "$version"
                    return 0
                fi
            fi
        else
            log_debug "Arquivo utils/common.sh não encontrado para: $software_name"
        fi
    fi

    # Fallback: try to call get_current_version if it exists in current context
    if declare -f get_current_version > /dev/null 2>&1; then
        log_debug "Obtendo versão atual via get_current_version() do contexto"

        local version=$(get_current_version 2> /dev/null)
        if [ -n "$version" ] && [ "$version" != "desconhecida" ]; then
            echo "$version"
            return 0
        fi
    fi

    echo "N/A"
    return 0
}

# Gets latest available version from remote source by calling get_latest_version() from command context
# This function should only be called within a command's execution context (e.g., --info flag)
# Args: software_name (optional) - name of the setup command
# Returns: version string or "N/A"
get_latest_software_version() {
    local software_name="${1:-}"

    # If no software name provided, try to get from context
    if [ -z "$software_name" ]; then
        software_name=$(context_get "command.current" 2> /dev/null || echo "")
    fi

    # If we have a software name, try to load its utils and get version
    if [ -n "$software_name" ]; then
        local common_utils="$CLI_DIR/commands/setup/$software_name/utils/common.sh"

        if [ -f "$common_utils" ]; then
            log_debug "Obtendo última versão de $software_name"

            # Source the file (suppress readonly errors)
            source "$common_utils" 2> /dev/null || true

            # Now call the function if it exists
            if declare -f get_latest_version > /dev/null 2>&1; then
                local version=$(get_latest_version 2> /dev/null)
                if [ -n "$version" ] && [ "$version" != "desconhecida" ]; then
                    echo "$version"
                    return 0
                fi
            fi
        else
            log_debug "Arquivo utils/common.sh não encontrado para: $software_name"
        fi
    fi

    # Fallback: try to call get_latest_version if it exists in current context
    if declare -f get_latest_version > /dev/null 2>&1; then
        log_debug "Obtendo última versão via get_latest_version() do contexto"

        local version=$(get_latest_version 2> /dev/null)
        if [ -n "$version" ] && [ "$version" != "desconhecida" ]; then
            echo "$version"
            return 0
        fi
    fi

    echo "N/A"
    return 0
}

# Displays formatted installation info: status, location, versions, updates
# Calls show_additional_info() if defined for custom information
# Args:
#   $1 - software_name (optional): nome do comando SUSA (ex: "vscode", "docker")
#                                 Se não fornecido, tenta obter do contexto
#   $2 - binary_name (optional): nome do binário no sistema (ex: "code", "docker")
#                               Se não fornecido, assume o mesmo que software_name
# Usage:
#   show_software_info                    # Usa contexto automaticamente
#   show_software_info "docker" "docker"  # Especifica nome
#   show_software_info "vscode" "code"    # Nome comando diferente do binário
show_software_info() {
    local software_name="${1:-}"
    local binary_name="${2:-}"

    # Try to get from context if not provided
    if [ -z "$software_name" ]; then
        software_name=$(context_get "command.current" 2> /dev/null || echo "")
    fi

    # Validate software name is provided
    if [ -z "$software_name" ]; then
        log_error "Nome do comando não fornecido e contexto não disponível"
        return 1
    fi

    # If binary_name not provided, use software_name
    if [ -z "$binary_name" ]; then
        binary_name="$software_name"
    fi

    log_debug "Exibindo informações para: $software_name (binário: $binary_name)"

    # Get display name from cache (performance optimized)
    local display_name=$(cache_query ".commands[] | select(.name == \"$software_name\") | .displayName // \"$software_name\"" 2> /dev/null)
    if [ -z "$display_name" ] || [ "$display_name" = "null" ]; then
        display_name="$software_name"
    fi
    log_debug "Display name: $display_name"

    # Get latest version
    log_debug "Obtendo última versão..."
    local latest_version=$(get_latest_software_version "$software_name" 2> /dev/null) || latest_version=""
    if [ -z "$latest_version" ] || [ "$latest_version" = "desconhecida" ] || [ "$latest_version" = "N/A" ] || [ "$latest_version" = "unknown" ] || [ "$latest_version" = "N/A" ]; then
        latest_version=""
    fi
    log_debug "Última versão processada: '$latest_version'"

    # Check installation status and display accordingly
    log_debug "Verificando status de instalação..."
    local is_installed=$(check_software_installed "$software_name" && echo "true" || echo "false")

    # Get current version
    local current_version=""
    local install_location=""
    if [ "$is_installed" = "true" ]; then
        log_debug "Obtendo versão atual..."
        current_version=$(get_current_software_version "$software_name" 2> /dev/null) || current_version=""
        if [ -z "$current_version" ] || [ "$current_version" = "desconhecida" ] || [ "$current_version" = "N/A" ] || [ "$current_version" = "unknown" ]; then
            current_version=""
        fi
        log_debug "Versão atual processada: '$current_version'"

        log_debug "Obtendo localização..."
        install_location=$(command -v "$binary_name" 2> /dev/null) || install_location=""
        if [ -z "$install_location" ] || [ "$install_location" = "desconhecida" ] || [ "$install_location" = "N/A" ] || [ "$install_location" = "unknown" ]; then
            install_location=""
        fi
        log_debug "Localização processada: '$install_location'"
    fi

    log_debug "Status de instalação para $software_name: $is_installed. Versão atual: $current_version. Última versão: $latest_version"

    # Display header
    log_output "${LIGHT_GREEN}Informações do $display_name:${NC}"
    log_output "  ${CYAN}Nome:${NC} $display_name"

    if [ "$is_installed" = "true" ]; then
        log_output "  ${CYAN}Status:${NC} ${GREEN}Instalado${NC}"
        log_output "  ${CYAN}Local:${NC} ${install_location:-Desconhecido}"
        log_output "  ${CYAN}Versão atual:${NC} ${current_version:-Desconhecida}"

        _display_latest_version_info "$current_version" "$latest_version"

        # Call custom additional info function if it exists
        declare -f show_additional_info > /dev/null 2>&1 && show_additional_info
    else
        log_output "  ${CYAN}Status:${NC} ${RED}Não instalado${NC}"
        _display_latest_version_info "" "$latest_version"
    fi
}

# Internal helper: Displays latest version information with appropriate formatting
# Args: current_version latest_version
# Usage: _display_latest_version_info "24.0.5" "24.0.6"
_display_latest_version_info() {
    local current="$1"
    local latest="$2"

    # Handle unavailable latest version
    if [ -z "$latest" ]; then
        log_output "  ${CYAN}Última versão:${NC} ${GRAY}indisponível${NC}"
        return
    fi

    # If current version is available, check for updates
    if [ -n "$current" ]; then
        local current_normalized="${current#v}"
        local latest_normalized="${latest#v}"

        if [ "$latest_normalized" != "$current_normalized" ]; then
            log_output "  ${CYAN}Última versão:${NC} ${YELLOW}$latest (atualização disponível)${NC}"
        else
            log_output "  ${CYAN}Última versão:${NC} ${latest:-Desconhecida}"
        fi
    else
        log_output "  ${CYAN}Última versão:${NC} ${latest:-Desconhecida}"
    fi
}

# Syncs system state with lock file: adds new installations, marks removed ones
# Two-pass scan: system → lock, then lock → system
# Usage: sync_installations
sync_installations() {
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        log_error "Lock file not found. Run 'susa self lock' first."
        return 1
    fi

    local synced_count=0
    local removed_count=0
    local temp_add_file="/tmp/susa_sync_add_$$"
    local temp_remove_file="/tmp/susa_sync_remove_$$"

    log_debug "Verificando instalações no sistema..."

    # Get all available setup commands
    local setup_base_commands=$(get_available_setup_commands)

    if [ -z "$setup_base_commands" ]; then
        log_warning "Nenhum comando de 'setup' encontrado"
        return 0
    fi

    # First pass: Check for new installations (system → lock)
    while IFS= read -r setup_base_command; do
        [ -z "$setup_base_command" ] && continue

        log_debug "Verificando: $setup_base_command"

        # Check if software is installed on system
        if check_software_installed "$setup_base_command"; then
            # Check if it's tracked in lock file
            if ! is_installed "$setup_base_command"; then
                # Get version (pass software name as parameter)
                local version=$(get_current_software_version "$setup_base_command")
                [ -z "$version" ] || [ "$version" = "N/A" ] && version="unknown"

                # Register in lock file
                register_or_update_software_in_lock "$setup_base_command" "$version"

                log_success "Sincronizado: $setup_base_command ($version)"

                # Track synced count in temp file
                echo "1" >> "$temp_add_file"
            else
                log_debug "$setup_base_command já está no lock file"
            fi
        else
            log_debug "$setup_base_command não está instalado"
        fi
    done <<< "$setup_base_commands"

    # Second pass: Check for removed installations (lock → system)
    log_debug "Verificando instalações removidas..."

    # Get list of software marked as installed in lock file
    local installed_in_lock=$(get_installed_from_cache)

    if [ -n "$installed_in_lock" ]; then
        while IFS= read -r setup_base_command; do
            [ -z "$setup_base_command" ] && continue

            log_debug "Verificando se $setup_base_command ainda está instalado..."

            # Check if software is still installed on system
            if ! check_software_installed "$setup_base_command"; then
                # Software was uninstalled, update lock file
                remove_software_in_lock "$setup_base_command"
                log_warning "Removido do lock: $setup_base_command (não está mais instalado)"

                # Track removed count in temp file
                echo "1" >> "$temp_remove_file"
            fi
        done <<< "$installed_in_lock"
    fi

    # Count changes from temp files
    if [ -f "$temp_add_file" ]; then
        synced_count=$(wc -l < "$temp_add_file" | tr -d ' ')
        rm -f "$temp_add_file"
    fi

    if [ -f "$temp_remove_file" ]; then
        removed_count=$(wc -l < "$temp_remove_file" | tr -d ' ')
        rm -f "$temp_remove_file"
    fi

    # Show summary
    echo ""
    if [ $synced_count -eq 0 ] && [ $removed_count -eq 0 ]; then
        log_info "Nenhuma alteração encontrada."
    else
        if [ $synced_count -gt 0 ]; then
            log_success "$synced_count software(s) adicionado(s) ao lock file."
        fi
        if [ $removed_count -gt 0 ]; then
            log_success "$removed_count software(s) removido(s) do lock file."
        fi
    fi

    return 0
}
