#!/bin/bash

# ============================================================
# Cache Management for SUSA CLI
# ============================================================
# Fast cache system to avoid parsing lock file with jq on every execution

# Cache configuration
CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/susa-$USER"
CACHE_FILE="$CACHE_DIR/lock.cache"
LOCK_FILE="${CLI_DIR:-$HOME/.susa}/susa.lock"

# Global variable to hold cached data in memory
_SUSA_CACHE_DATA=""
_SUSA_CACHE_LOADED=0

# ============================================================
# Internal Cache Functions
# ============================================================

# Initialize cache directory
_cache_init() {
    if [ ! -d "$CACHE_DIR" ]; then
        mkdir -p "$CACHE_DIR" 2> /dev/null || {
            log_debug "Não foi possível criar diretório de cache: $CACHE_DIR"
            return 1
        }
        chmod 700 "$CACHE_DIR" 2> /dev/null
    fi
    return 0
}

# Check if cache is valid (exists and is newer than lock file)
_cache_is_valid() {
    [ ! -f "$LOCK_FILE" ] && return 1
    [ ! -f "$CACHE_FILE" ] && return 1
    [ "$CACHE_FILE" -nt "$LOCK_FILE" ] && return 0
    return 1
}

# Update cache file from lock file
_cache_update() {
    if [ ! -f "$LOCK_FILE" ]; then
        log_debug "Lock file não encontrado: $LOCK_FILE"
        return 1
    fi

    _cache_init || return 1

    # Use jq to minify and validate JSON, then write to cache
    if jq -c '.' "$LOCK_FILE" > "$CACHE_FILE.tmp" 2> /dev/null; then
        mv "$CACHE_FILE.tmp" "$CACHE_FILE"
        log_debug "Cache atualizado: $CACHE_FILE"
        return 0
    else
        rm -f "$CACHE_FILE.tmp" 2> /dev/null
        log_debug "Erro ao atualizar cache do lock file"
        return 1
    fi
}

# ============================================================
# Public Cache Functions
# ============================================================

# Load cache data into memory
# This should be called once at CLI startup
cache_load() {
    # Already loaded, skip
    [ "$_SUSA_CACHE_LOADED" -eq 1 ] && return 0

    # Check if cache is valid, if not update it
    if ! _cache_is_valid; then
        _cache_update || {
            log_debug "Usando lock file diretamente (cache indisponível)"
            if [ -f "$LOCK_FILE" ]; then
                _SUSA_CACHE_DATA=$(jq -c '.' "$LOCK_FILE" 2> /dev/null)
                _SUSA_CACHE_LOADED=1
                return 0
            fi
            return 1
        }
    fi

    # Load cache into memory
    if [ -f "$CACHE_FILE" ]; then
        _SUSA_CACHE_DATA=$(cat "$CACHE_FILE" 2> /dev/null)
        _SUSA_CACHE_LOADED=1
        log_debug "Cache carregado em memória"
        return 0
    fi

    return 1
}

# Get data from cache using jq query
# Args: jq_query
# Example: cache_query '.categories[].name'
cache_query() {
    local query="$1"

    # Ensure cache is loaded
    cache_load || return 1

    # Query the in-memory cache data
    echo "$_SUSA_CACHE_DATA" | jq -r "$query" 2> /dev/null
}

# Get categories from cache
cache_get_categories() {
    cache_query '.categories[].name'
}

# Get category info from cache
# Args: category field
cache_get_category_info() {
    local category="$1"
    local field="$2"
    cache_query ".categories[] | select(.name == \"$category\") | .$field"
}

# Get commands from category from cache
# Args: category
cache_get_category_commands() {
    local category="$1"
    cache_query ".commands[] | select(.category == \"$category\") | .name"
}

# Get command info from cache
# Args: category command field
cache_get_command_info() {
    local category="$1"
    local command="$2"
    local field="$3"
    cache_query ".commands[] | select(.category == \"$category\" and .name == \"$command\") | .$field"
}

# Get plugin info from cache
# Args: plugin_name field
cache_get_plugin_info() {
    local plugin_name="$1"
    local field="$2"
    cache_query ".plugins[] | select(.name == \"$plugin_name\") | .$field"
}

# Get all plugins from cache
cache_get_plugins() {
    cache_query '.plugins[].name'
}

# Force cache refresh
cache_refresh() {
    _SUSA_CACHE_LOADED=0
    _SUSA_CACHE_DATA=""
    _cache_update
    cache_load
}

# Clear cache
cache_clear() {
    _SUSA_CACHE_LOADED=0
    _SUSA_CACHE_DATA=""
    rm -f "$CACHE_FILE" 2> /dev/null
    log_debug "Cache limpo"
}

# Check if cache exists and is valid
cache_exists() {
    _cache_is_valid
}

# Get cache info for debugging
cache_info() {
    log_output "${BOLD}${CYAN}Informações do Cache${NC}"
    log_output "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    log_output "${BOLD}Localização:${NC}"
    log_output "  ${GRAY}Diretório:${NC} $CACHE_DIR"
    log_output "  ${GRAY}Arquivo:${NC}   $CACHE_FILE"
    log_output "  ${GRAY}Lock:${NC}      $LOCK_FILE"
    echo ""

    log_output "${BOLD}Status do Cache:${NC}"
    if [ -f "$CACHE_FILE" ]; then
        local cache_size=$(du -h "$CACHE_FILE" | cut -f1)
        local cache_date=$(stat -c %y "$CACHE_FILE" 2> /dev/null || stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$CACHE_FILE" 2> /dev/null)
        log_output "  ${GRAY}Existe:${NC}      ${GREEN}✓ Sim${NC}"
        log_output "  ${GRAY}Tamanho:${NC}     $cache_size"
        log_output "  ${GRAY}Modificado:${NC}  $cache_date"
    else
        log_output "  ${GRAY}Existe:${NC}      ${RED}✗ Não${NC}"
    fi
    echo ""

    log_output "${BOLD}Status do Lock File:${NC}"
    if [ -f "$LOCK_FILE" ]; then
        local lock_date=$(stat -c %y "$LOCK_FILE" 2> /dev/null || stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$LOCK_FILE" 2> /dev/null)
        log_output "  ${GRAY}Existe:${NC}      ${GREEN}✓ Sim${NC}"
        log_output "  ${GRAY}Modificado:${NC}  $lock_date"
    else
        log_output "  ${GRAY}Existe:${NC}      ${RED}✗ Não${NC}"
    fi
    echo ""

    log_output "${BOLD}Validação:${NC}"
    if _cache_is_valid; then
        log_output "  ${GRAY}Status:${NC}      ${GREEN}✓ Válido${NC}"
        log_output "  ${GRAY}Descrição:${NC}   Cache está atualizado e pronto para uso"
    else
        log_output "  ${GRAY}Status:${NC}      ${YELLOW}⚠ Inválido ou Desatualizado${NC}"
        log_output "  ${GRAY}Descrição:${NC}   Cache será regenerado na próxima execução"
    fi
}
