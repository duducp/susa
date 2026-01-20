#!/bin/bash

# ============================================================
# Cache Management for SUSA CLI
# ============================================================
# Generic named cache system for fast data access in memory
# All caches use associative arrays for maximum performance

# Check Bash version (requires 4+ for associative arrays)
if ((BASH_VERSINFO[0] < 4)); then
    log_error "Erro: Este sistema requer Bash 4.0 ou superior" >&2
    log_output "Versão atual: $BASH_VERSION" >&2
    if [[ "$(uname)" == "Darwin" ]]; then
        log_output "Para macOS, instale via: brew install bash" >&2
    fi
    exit 1
fi

# Determine cache directory based on OS
# Linux: Use XDG_RUNTIME_DIR or /tmp/susa-$USER
# macOS: Use TMPDIR (user-specific) or ~/Library/Caches/susa
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS: TMPDIR is user-specific and cleaned on logout
    CACHE_DIR="${TMPDIR:-$HOME/Library/Caches}/susa"
else
    # Linux: XDG_RUNTIME_DIR is the standard, fallback to /tmp
    CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/susa-$USER"
fi

# Associative arrays for named caches (bash 4+)
# Only declare if not already declared (prevent reset on re-source)
if [ -z "${_SUSA_NAMED_CACHES_INITIALIZED+x}" ]; then
    declare -gA _SUSA_NAMED_CACHES
    declare -gA _SUSA_NAMED_CACHES_LOADED
    _SUSA_NAMED_CACHES_INITIALIZED=1
fi

# ============================================================
# Internal Cache Functions
# ============================================================

# Initialize cache directory
_cache_init() {
    log_trace "Chamando _cache_init()"

    if [ ! -d "$CACHE_DIR" ]; then
        log_debug2 "Criando diretório de cache: $CACHE_DIR"
        mkdir -p "$CACHE_DIR" 2> /dev/null || {
            log_error "Não foi possível criar diretório de cache: $CACHE_DIR"
            return 1
        }
        chmod 700 "$CACHE_DIR" 2> /dev/null
        log_debug "Diretório de cache criado: $CACHE_DIR"
    fi
    return 0
}

# Get cache file path for named cache
_cache_named_file() {
    local name="$1"
    echo "$CACHE_DIR/${name}.cache"
}

# Load named cache into memory from file or source file
# Args: cache_name [source_file]
# If source_file provided and cache doesn't exist or is older, loads from source
cache_named_load() {
    local name="$1"
    local source_file="${2:-}"

    log_trace "Chamando cache_named_load(name=$name, source_file=$source_file)"

    if [ -z "$name" ]; then
        log_error "cache_named_load: nome do cache não pode ser vazio"
        return 1
    fi

    # Already loaded, skip
    if [ "${_SUSA_NAMED_CACHES_LOADED[$name]:-0}" -eq 1 ]; then
        return 0
    fi

    _cache_init || return 1

    local cache_file=$(_cache_named_file "$name")

    # If source file provided, check if cache needs update
    if [ -n "$source_file" ] && [ -f "$source_file" ]; then
        local needs_update=0

        # Cache doesn't exist
        if [ ! -f "$cache_file" ]; then
            needs_update=1
        # Source is newer than cache
        elif [ "$source_file" -nt "$cache_file" ]; then
            needs_update=1
        fi

        # Update cache from source if needed
        if [ $needs_update -eq 1 ]; then
            log_debug "Atualizando cache '$name' de: $source_file"
            if jq -c '.' "$source_file" > "${cache_file}.tmp" 2> /dev/null; then
                mv "${cache_file}.tmp" "$cache_file"
                chmod 600 "$cache_file"
                log_debug2 "Cache '$name' salvo em: $cache_file"
            else
                rm -f "${cache_file}.tmp" 2> /dev/null
                # Fallback: load directly from source
                log_debug2 "Usando arquivo fonte diretamente: $source_file"
                _SUSA_NAMED_CACHES[$name]=$(jq -c '.' "$source_file" 2> /dev/null)
                _SUSA_NAMED_CACHES_LOADED[$name]=1
                return 0
            fi
        fi
    fi

    # If cache doesn't exist, create empty object
    if [ ! -f "$cache_file" ]; then
        echo '{}' > "$cache_file"
        chmod 600 "$cache_file"
    fi

    # Load cache into memory
    _SUSA_NAMED_CACHES[$name]=$(cat "$cache_file" 2> /dev/null)
    _SUSA_NAMED_CACHES_LOADED[$name]=1
    log_debug2 "Cache carregado: $name"
    return 0
}

# Query named cache with jq
# Args: cache_name jq_query
cache_named_query() {
    local name="$1"
    local query="$2"

    log_trace "Chamando cache_named_query(name=$name, query=$query)"

    if [ -z "$name" ] || [ -z "$query" ]; then
        log_error "cache_named_query: nome e query são obrigatórios"
        return 1
    fi

    # Ensure cache is loaded
    cache_named_load "$name" || return 1

    # Query the in-memory cache data
    echo "${_SUSA_NAMED_CACHES[$name]}" | jq -r "$query" 2> /dev/null
}

# Set a value in named cache
# Args: cache_name key value
cache_named_set() {
    local name="$1"
    local key="$2"
    local value="$3"

    log_trace "Chamando cache_named_set(name=$name, key=$key)"

    if [ -z "$name" ] || [ -z "$key" ]; then
        log_error "cache_named_set: nome e chave são obrigatórios"
        return 1
    fi

    # Ensure cache is loaded
    cache_named_load "$name" || return 1

    # Update in-memory cache
    local updated_data
    updated_data=$(echo "${_SUSA_NAMED_CACHES[$name]}" |
        jq --arg key "$key" --arg value "$value" \
            '. + {($key): $value}' 2> /dev/null)

    if [ $? -eq 0 ]; then
        _SUSA_NAMED_CACHES[$name]="$updated_data"
        log_debug2 "Cache atualizado: $name.$key = $value"
        return 0
    else
        log_error "Erro ao atualizar cache nomeado"
        return 1
    fi
}

# Get a value from named cache
# Args: cache_name key
cache_named_get() {
    local name="$1"
    local key="$2"

    log_trace "Chamando cache_named_get(name=$name, key=$key)"

    if [ -z "$name" ] || [ -z "$key" ]; then
        log_error "cache_named_get: nome e chave são obrigatórios"
        return 1
    fi

    # Ensure cache is loaded
    cache_named_load "$name" || return 1

    # Get value from in-memory cache
    echo "${_SUSA_NAMED_CACHES[$name]}" |
        jq -r --arg key "$key" '.[$key] // empty' 2> /dev/null || true
}

# Check if key exists in named cache
# Args: cache_name key
cache_named_has() {
    local name="$1"
    local key="$2"

    if [ -z "$name" ] || [ -z "$key" ]; then
        log_error "cache_named_has: nome e chave são obrigatórios"
        return 1
    fi

    # Ensure cache is loaded
    cache_named_load "$name" || return 1

    # Check if key exists
    local result
    result=$(echo "${_SUSA_NAMED_CACHES[$name]}" |
        jq -r --arg key "$key" 'has($key)' 2> /dev/null || echo "false")

    [ "$result" = "true" ] && return 0 || return 1
}

# Get all data from named cache
# Args: cache_name
cache_named_get_all() {
    local name="$1"

    if [ -z "$name" ]; then
        log_error "cache_named_get_all: nome do cache não pode ser vazio"
        return 1
    fi

    # Ensure cache is loaded
    cache_named_load "$name" || return 1

    echo "${_SUSA_NAMED_CACHES[$name]}"
}

# Remove a key from named cache
# Args: cache_name key
cache_named_remove() {
    local name="$1"
    local key="$2"

    if [ -z "$name" ] || [ -z "$key" ]; then
        log_error "cache_named_remove: nome e chave são obrigatórios"
        return 1
    fi

    # Ensure cache is loaded
    cache_named_load "$name" || return 1

    # Remove key from in-memory cache
    local updated_data
    updated_data=$(echo "${_SUSA_NAMED_CACHES[$name]}" |
        jq --arg key "$key" 'del(.[$key])' 2> /dev/null)

    if [ $? -eq 0 ]; then
        _SUSA_NAMED_CACHES[$name]="$updated_data"
        log_debug "Chave removida do cache: $name.$key"
        return 0
    else
        log_error "Erro ao remover chave do cache nomeado"
        return 1
    fi
}

# Save named cache to disk
# Args: cache_name
cache_named_save() {
    local name="$1"

    log_trace "Chamando cache_named_save(name=$name)"

    if [ -z "$name" ]; then
        log_error "cache_named_save: nome do cache não pode ser vazio"
        return 1
    fi

    # Check if cache is loaded
    if [ "${_SUSA_NAMED_CACHES_LOADED[$name]:-0}" -eq 0 ]; then
        log_debug2 "Cache não carregado, nada para salvar: $name"
        return 0
    fi

    local cache_file=$(_cache_named_file "$name")

    # Write to disk
    echo "${_SUSA_NAMED_CACHES[$name]}" > "$cache_file"
    chmod 600 "$cache_file"
    log_debug "Cache salvo em disco: $name"
    log_debug2 "Arquivo de cache: $cache_file"
}

# Clear named cache
# Args: cache_name
cache_named_clear() {
    local name="$1"

    log_trace "Chamando cache_named_clear(name=$name)"

    if [ -z "$name" ]; then
        log_error "cache_named_clear: nome do cache não pode ser vazio"
        return 1
    fi

    # Clear from memory
    unset '_SUSA_NAMED_CACHES[$name]'
    unset '_SUSA_NAMED_CACHES_LOADED[$name]'

    # Remove file
    local cache_file=$(_cache_named_file "$name")
    rm -f "$cache_file" 2> /dev/null

    log_debug2 "Cache limpo: $name"
}

# List all keys in named cache
# Args: cache_name
cache_named_keys() {
    local name="$1"

    if [ -z "$name" ]; then
        log_error "cache_named_keys: nome do cache não pode ser vazio"
        return 1
    fi

    # Ensure cache is loaded
    cache_named_load "$name" || return 1

    echo "${_SUSA_NAMED_CACHES[$name]}" | jq -r 'keys[]' 2> /dev/null || true
}

# Count keys in named cache
# Args: cache_name
cache_named_count() {
    local name="$1"

    if [ -z "$name" ]; then
        log_error "cache_named_count: nome do cache não pode ser vazio"
        return 1
    fi

    # Ensure cache is loaded
    cache_named_load "$name" || return 1

    echo "${_SUSA_NAMED_CACHES[$name]}" | jq 'keys | length' 2> /dev/null || echo "0"
}
