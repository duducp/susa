#!/bin/bash
#
# context.sh - Command execution context system
#
# Provides functions to manage an execution context that persists
# during a command's lifetime and is automatically cleaned up after.
#
# Uses the named cache system for optimized performance.
#
# Dependencies:
#   - core/lib/internal/cache.sh (required)
#   - core/lib/logger.sh (optional - for logging)
#

set -euo pipefail
IFS=$'\n\t'

# Name of the cache used for context
CONTEXT_CACHE_NAME="context"

# Helper for compatible logging (works even without logger.sh)
_context_log_debug() {
    if command -v log_debug &> /dev/null; then
        log_debug "$@"
    fi
}

_context_log_error() {
    if command -v log_error &> /dev/null; then
        log_error "$@"
    else
        echo "ERROR: $*" >&2
    fi
}

# Initialize context (clears if exists)
# Should be called at the beginning of each command execution
context_init() {
    cache_named_clear "$CONTEXT_CACHE_NAME"
    cache_named_load "$CONTEXT_CACHE_NAME"
    _context_log_debug "Context initialized"
}

# Set a value in the context
# Usage: context_set "key" "value"
context_set() {
    local key="$1"
    local value="$2"

    if [ -z "$key" ]; then
        _context_log_error "context_set: key cannot be empty"
        return 1
    fi

    cache_named_set "$CONTEXT_CACHE_NAME" "$key" "$value"
}

# Get a value from the context
# Usage: context_get "key"
# Returns: key value or empty string if not exists
context_get() {
    local key="$1"

    if [ -z "$key" ]; then
        _context_log_error "context_get: key cannot be empty"
        return 1
    fi

    cache_named_get "$CONTEXT_CACHE_NAME" "$key"
}

# Check if a key exists in the context
# Usage: context_has "key"
# Returns: 0 if exists, 1 if not exists
context_has() {
    local key="$1"

    if [ -z "$key" ]; then
        _context_log_error "context_has: key cannot be empty"
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
        _context_log_error "context_remove: key cannot be empty"
        return 1
    fi

    cache_named_remove "$CONTEXT_CACHE_NAME" "$key"
}

# Save context to disk (optional - useful for debugging)
# Usage: context_save
context_save() {
    cache_named_save "$CONTEXT_CACHE_NAME"
    _context_log_debug "Context saved to disk"
}

# Clear entire context
# Should be called at the end of each command execution
context_clear() {
    cache_named_clear "$CONTEXT_CACHE_NAME"
    _context_log_debug "Context cleared"
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
