#!/bin/bash

source "$LIB_DIR/color.sh"

# Prints a dynamic message to the shell, overwriting the previous line.
# Usage: dynamic_message "Your message"
# Example:
#   dynamic_message "Loading..."
#   sleep 1
#   dynamic_message "Done!"
dynamic_message() {
    local message="$1"
    # \r returns to the beginning of the line, overwriting the previous message
    echo -ne "\r$message"
}

# Clears the current dynamic line in the shell.
# Usage: dynamic_clear
# Example:
#   dynamic_message "Temporary message"
#   sleep 1
#   dynamic_clear
# Clears the dynamic line
dynamic_clear() {
    echo -ne "\r\033[K"
}

## Displays a spinner animation in the shell.
# Usage:
#   dynamic_spinner "Message" [pid] [delay] [success_symbol] [fail_symbol] [duration]
#
# Parameters:
#   message         - Text to display next to the spinner
#   pid (optional)  - PID of a background process to monitor
#   delay (optional)- Spinner frame interval in seconds (default: 0.08)
#   success_symbol  - Symbol to show on success (default: ✔)
#   fail_symbol     - Symbol to show on failure (default: ✖)
#   duration        - If no PID, spinner runs for this many seconds
#
# Examples:
#   # Spinner for a background process
#   long_running_command &
#   pid=$!
#   dynamic_spinner "Waiting for process" "$pid"
#
#   # Spinner for 5 seconds (no PID)
#   dynamic_spinner "Processing..." "" 0.08 "✔" "✖" 5
#
#   # Custom spinner, success/fail symbols
#   dynamic_spinner "Custom" "" 0.1 "OK" "FAIL" 3
dynamic_spinner() {
    local message="$1"
    local pid="${2:-}"
    local delay="${3:-0.08}"
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local success_symbol="${4:-✔}"
    local fail_symbol="${5:-✖}"
    local duration="${6:-}"
    local i=0
    local start_time=$(date +%s)
    local frame_count=${#frames[@]}
    local exit_code=0
    if [ -n "$pid" ]; then
        # Spinner loop for process
        while kill -0 "$pid" 2> /dev/null; do
            local frame="${frames[i++ % frame_count]}"
            local elapsed=$(($(date +%s) - start_time))
            echo -ne "\r${LIGHT_CYAN}${frame} ${message} ${NC}[${elapsed}s]"
            sleep "$delay"
        done
        wait "$pid"
        exit_code=$?
        local elapsed=$(($(date +%s) - start_time))
        if [ "$exit_code" -eq 0 ]; then
            echo -ne "\r${LIGHT_CYAN}${success_symbol} ${message} ${NC}[${elapsed}s]\n"
        else
            echo -ne "\r${LIGHT_CYAN}${fail_symbol} ${message} ${NC}[${elapsed}s]\n"
        fi
    else
        # Spinner loop for fixed duration or until interrupted
        local elapsed=0
        while :; do
            local frame="${frames[i++ % frame_count]}"
            elapsed=$(($(date +%s) - start_time))
            echo -ne "\r${LIGHT_CYAN}${frame} ${message} ${NC}[${elapsed}s]"
            sleep "$delay"
            if [ -n "$duration" ] && [ "$elapsed" -ge "$duration" ]; then
                break
            fi
        done
        echo -ne "\r${LIGHT_CYAN}${success_symbol} ${message} ${NC}[${elapsed}s]\n"
    fi
}
