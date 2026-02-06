#!/usr/bin/env zsh
#
# context.sh - Command execution context system
#
# Provides functions to manage an execution context that persists
# during a command's lifetime and is automatically cleaned up after.
#
# Uses the named cache system for optimized performance.
#
# Dependencies:
#   - core/lib/cache.sh (required)
#   - core/lib/logger.sh (optional - for logging)
#

# Name of the cache used for context
CONTEXT_CACHE_NAME="context"

# Initialize context (clears if exists)
# Should be called at the beginning of each command execution
context_init() {
    cache_named_clear "$CONTEXT_CACHE_NAME"
    cache_named_load "$CONTEXT_CACHE_NAME"
}

# Set a value in the context
# Usage: context_set "key" "value"
context_set() {
    local key="$1"
    local value="$2"

    if [ -z "$key" ]; then
        log_error "context_set: a chave não pode estar vazia"
        return 1
    fi

    cache_named_set "$CONTEXT_CACHE_NAME" "$key" "$value"
    log_trace "Contexto adicionado para $key"
}

# Get a value from the context
# Usage: context_get "key"
# Returns: key value or empty string if not exists
context_get() {
    local key="$1"

    if [ -z "$key" ]; then
        log_error "context_get: a chave não pode estar vazia"
        return 1
    fi

    cache_named_get "$CONTEXT_CACHE_NAME" "$key"
    log_trace "Contexto obtido para $key"
}

# Check if a key exists in the context
# Usage: context_has "key"
# Returns: 0 if exists, 1 if not exists
context_has() {
    local key="$1"

    if [ -z "$key" ]; then
        log_error "context_has: a chave não pode estar vazia"
        return 1
    fi

    cache_named_has "$CONTEXT_CACHE_NAME" "$key"
}

# Get entire context as JSON
# Usage: context_get_all
# Returns: JSON with entire context
context_get_all() {
    cache_named_get_all "$CONTEXT_CACHE_NAME"
}

# Remove a key from the context
# Usage: context_remove "key"
context_remove() {
    local key="$1"

    if [ -z "$key" ]; then
        log_error "context_remove: a chave não pode estar vazia"
        return 1
    fi

    cache_named_remove "$CONTEXT_CACHE_NAME" "$key"
    log_trace "Contexto removido para $key"
}

# Save context to disk (optional - useful for debugging)
# Usage: context_save
context_save() {
    cache_named_save "$CONTEXT_CACHE_NAME"
    log_trace "Contexto salvo"
}

# Clear entire context
# Should be called at the end of each command execution
context_clear() {
    cache_named_clear "$CONTEXT_CACHE_NAME"
    log_trace "Contexto limpo"
}

# List all context keys
# Usage: context_keys
# Returns: Array of keys (one per line)
context_keys() {
    cache_named_keys "$CONTEXT_CACHE_NAME"
}

# Count how many keys exist in the context
# Usage: context_count
# Returns: Number of keys
context_count() {
    cache_named_count "$CONTEXT_CACHE_NAME"
}

# Print all context data (useful for debugging)
# Usage: print_context
# Outputs: Formatted list of all context keys and values
print_context() {
    local count=$(context_count)

    log_output ""
    log_output "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    log_output "${CYAN}📋 Context Debug${RESET}"
    log_output "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    if [ "$count" -eq 0 ]; then
        log_output "${YELLOW}  (vazio)${RESET}"
    else
        local keys
        keys=$(context_keys)

        while IFS= read -r key; do
            [ -z "$key" ] && continue
            local value=$(context_get "$key")
            log_output "${GREEN}  $key:${RESET} $value"
        done <<< "$keys"
    fi

    log_output "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    log_output "${DIM}Total: $count item(s)${RESET}"
    log_output ""
}
