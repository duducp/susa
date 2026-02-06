#!/usr/bin/env zsh

# --- Sudo Helper Functions --- #

# Check if the script is running with superuser privileges
# Returns:
#   0 - If running as root
#   1 - If not running with root privileges
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        log_warning "Este comando requer privilégios de superusuário (sudo)." >&2
        return 1
    fi
    return 0
}

# Check if any argument should bypass sudo requirement
# Arguments that don't need sudo execution (e.g., help, version, info commands)
# Args:
#   $@ - All command arguments
# Returns:
#   0 - If bypass is allowed
#   1 - If sudo should be required
should_bypass_sudo() {
    local bypass_args=(
        "-h"
        "--help"
        "help"
        "-v"
        "--version"
        "version"
        "--info"
    )

    for arg in "$@"; do
        for bypass in "${bypass_args[@]}"; do
            if [ "$arg" = "$bypass" ]; then
                return 0
            fi
        done
    done

    return 1
}

# Ensure the script has superuser privileges
# If not running as root, requests sudo authentication
# Exits with error if authentication fails
# Args:
#   $@ - Command arguments (checked for bypass)
required_sudo() {
    # Check if any argument allows bypass
    if should_bypass_sudo "$@"; then
        return 0
    fi

    if ! check_sudo; then
        sudo -v || {
            log_error "Falha ao obter privilégios de sudo"
            exit 1
        }
    fi
}
