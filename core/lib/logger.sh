#!/usr/bin/env zsh

# Lazy load string.sh only if needed (optimization)
if ! declare -f strtobool &> /dev/null; then
    source "$LIB_DIR/string.sh"
fi

# ============================================================
# Logger Library
# ============================================================
# Provides logging functions with different levels and colors
# Respects SILENT and DEBUG environment variables
# Supports verbose levels: 1 (debug), 2 (debug2), 3 (trace)

# ============================================================
# Constants
# ============================================================

readonly LOG_LEVEL_ERROR=0
readonly LOG_LEVEL_WARNING=1
readonly LOG_LEVEL_INFO=2
readonly LOG_LEVEL_DEBUG=3
readonly LOG_LEVEL_TRACE=4

# ============================================================
# Internal Functions
# ============================================================

# Get current verbosity level
_get_verbose_level() {
    echo "${VERBOSE_LEVEL:-0}"
}

# Check if silent mode is enabled
_is_silent() {
    strtobool "${SILENT:-false}"
}

# Check if debug mode is enabled
_is_debug() {
    strtobool "${DEBUG:-false}"
}

# ============================================================
# Public Functions
# ============================================================

# Output without timestamp or prefix (for formatted messages)
# Usage: log_output "${GREEN}Success:${NC} Operation completed"
log_output() {
    _is_silent && return 0
    echo -e "$*" >&2
}

# Generic message with timestamp
# Usage: log_message "Processing file"
log_message() {
    _is_silent && return 0
    echo -e "[MESSAGE] ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $*" >&2
}

# Info level message (general information)
# Usage: log_info "Starting installation"
log_info() {
    _is_silent && return 0
    echo -e "${CYAN}[INFO]${NC} ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $*" >&2
}

# Success message (operation completed successfully)
# Usage: log_success "Docker installed successfully"
log_success() {
    _is_silent && return 0
    echo -e "${GREEN}[SUCCESS]${NC} ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $*" >&2
}

# Warning message (non-critical issues)
# Usage: log_warning "Cache is outdated"
log_warning() {
    _is_silent && return 0
    echo -e "${YELLOW}[WARNING]${NC} ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $*" >&2
}

# Error message (critical issues)
# Usage: log_error "Failed to download file"
log_error() {
    _is_silent && return 0
    echo -e "${RED}[ERROR]${NC} ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $*" >&2
}

# Debug output - Verbose level 1+ (-v, --verbose)
# Shows general debug information
# Usage: log_debug "Detected OS: Linux"
log_debug() {
    _is_silent && return 0
    _is_debug || return 0

    local level=$(_get_verbose_level)
    [ "$level" -ge 1 ] || return 0

    echo -e "${LIGHT_GRAY}[DEBUG]${NC} $*" >&2
}

# Detailed debug - Verbose level 2+ (-vv)
# Shows detailed debugging information
# Usage: log_debug2 "Cache hit: version=24.0.5"
log_debug2() {
    _is_silent && return 0
    _is_debug || return 0

    local level=$(_get_verbose_level)
    [ "$level" -ge 2 ] || return 0

    echo -e "${LIGHT_GRAY}[DEBUG2]${NC} $*" >&2
}

# Trace output - Verbose level 3+ (-vvv)
# Shows function calls and detailed execution flow
# Usage: log_trace "Calling detect_os_arch()"
log_trace() {
    _is_silent && return 0
    _is_debug || return 0

    local level=$(_get_verbose_level)
    [ "$level" -ge 3 ] || return 0

    echo -e "${GRAY}[TRACE]${NC} $*" >&2
}

# ============================================================
# Helper Functions
# ============================================================

# Check if debug mode is active (for conditional logic)
# Usage: is_debug_enabled && complex_debug_operation
is_debug_enabled() {
    _is_debug && [ "$(_get_verbose_level)" -ge 1 ]
}

# Check if trace mode is active (for conditional logic)
# Usage: is_trace_enabled && very_verbose_operation
is_trace_enabled() {
    _is_debug && [ "$(_get_verbose_level)" -ge 3 ]
}
