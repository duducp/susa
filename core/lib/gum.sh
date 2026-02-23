#!/usr/bin/env zsh
# gum.sh - Interactive UI components library using Gum
#
# This library provides high-level wrappers around Gum (https://github.com/charmbracelet/gum)
# for creating beautiful, interactive CLI experiences.
#
# Dependencies: gum (https://github.com/charmbracelet/gum) - REQUIRED
#
# Usage:
#   source "$LIB_DIR/gum.sh"
#
# Functions:
#   - gum_is_available()              Check if gum is installed
#   - gum_require()                   Ensure gum is installed (exits if not)
#   - gum_input()                     Get user input with validation
#   - gum_confirm()                   Ask for confirmation
#   - gum_choose()                    Single selection from list
#   - gum_choose_multi()              Multiple selections from list
#   - gum_filter()                    Fuzzy filter selection
#   - gum_spin()                      Show spinner during operation
#   - gum_spin_start()                Start spinner in background (manual control)
#   - gum_spin_stop()                 Stop background spinner
#   - gum_spin_update()               Update spinner message (restart with new message)
#   - gum_progress()                  Show progress bar
#   - gum_pager()                     Show content in pager
#   - gum_format()                    Format markdown text
#   - gum_style()                     Style text with colors/formatting

# ============================================================
# Availability Check
# ============================================================

# Check if gum is available
# Returns: 0 if available, 1 otherwise
gum_is_available() {
    command -v gum &> /dev/null
}

# Ensure gum is available, exit with message if not
# Usage: gum_require
gum_require() {
    if ! gum_is_available; then
        log_error "GUM não está instalado"
        log_output ""
        log_output "Instale o GUM para usar este recurso:"
        log_output "  ${LIGHT_CYAN}susa setup gum${NC}"
        log_output ""
        log_output "Ou visite: https://github.com/charmbracelet/gum"
        exit 1
    fi
}

# ============================================================
# Input Functions
# ============================================================

# Get user input with optional prompt and placeholder
# Usage: gum_input [prompt] [placeholder] [default]
# Returns: User input
gum_input() {
    gum_require

    local prompt="${1:-Digite:}"
    local placeholder="${2:-}"
    local default="${3:-}"

    local args=(--prompt "$prompt ")
    [ -n "$placeholder" ] && args+=(--placeholder "$placeholder")
    [ -n "$default" ] && args+=(--value "$default")

    gum input "${args[@]}"
}

# Get password input (hidden)
# Usage: gum_input_password [prompt]
# Returns: Password
gum_input_password() {
    gum_require

    local prompt="${1:-Senha:}"
    gum input --password --prompt "$prompt "
}

# ============================================================
# Confirmation Functions
# ============================================================

# Ask for confirmation
# Usage: gum_confirm [prompt] [default]
# Returns: 0 if yes, 1 if no
gum_confirm() {
    gum_require

    local prompt="${1:-Continuar?}"
    local default="${2:-no}" # yes or no

    local args=(
        "$prompt"
        --affirmative "Sim"
        --negative "Não"
        --prompt.foreground="214"
        --selected.background="214"
        --selected.foreground="0"
        --selected.bold
        --unselected.foreground="245"
    )
    [ "$default" = "yes" ] && args+=(--default=true)

    gum confirm "${args[@]}"
}

# ============================================================
# Selection Functions
# ============================================================

# Single selection from list
# Usage: gum_choose [header] [options...]
# Returns: Selected option
gum_choose() {
    gum_require

    local header="$1"
    shift
    local options=("$@")

    gum choose --header "$header" --height 15 "${options[@]}"
}

# Multiple selections from list
# Usage: gum_choose_multi [header] [limit] [options...]
# Returns: Selected options (one per line)
gum_choose_multi() {
    gum_require

    local header="$1"
    local limit="$2"
    shift 2
    local options=("$@")

    local args=(--header "$header" --no-limit)
    [ "$limit" != "0" ] && args+=(--limit "$limit")

    gum choose --no-limit "${args[@]}" "${options[@]}"
}

# Fuzzy filter selection
# Usage: gum_filter [placeholder] [options...]
# Returns: Selected option
gum_filter() {
    gum_require

    local placeholder="$1"
    shift
    local options=("$@")

    printf '%s\n' "${options[@]}" | gum filter --placeholder "$placeholder" --height 15
}

# ============================================================
# Progress Indicators
# ============================================================

# Global variable to track active spinner PID
_GUM_SPIN_PID=""
_GUM_SPIN_TEMP=""

# Start spinner in background (manual control)
# Usage: gum_spin_start "Loading..."
# Returns: 0 if started, 1 if already running
gum_spin_start() {
    gum_require

    local title="${1:-Processando...}"

    log_trace "Iniciando spinner com título: $title"

    # Stop existing spinner if running
    gum_spin_stop

    # Create temp file to track spinner
    _GUM_SPIN_TEMP=$(mktemp)

    # Start spinner in background with sleep (use large number for macOS compatibility)
    gum spin --spinner dot --title "$title" --spinner.foreground 214 -- sleep 2147483647 &

    _GUM_SPIN_PID=$!
    echo $_GUM_SPIN_PID > "$_GUM_SPIN_TEMP"
    log_trace "Spinner iniciado (PID: $_GUM_SPIN_PID)"

    # Give spinner a tiny moment to start rendering
    sleep 0.02s
}

# Stop spinner started with gum_spin_start
# Usage: gum_spin_stop
gum_spin_stop() {
    if [ -n "$_GUM_SPIN_PID" ] && kill -0 "$_GUM_SPIN_PID" 2> /dev/null; then
        kill -TERM "$_GUM_SPIN_PID" 2> /dev/null || true
        # Don't wait, just move on
        _GUM_SPIN_PID=""
    fi

    # Clean up temp file
    if [ -n "$_GUM_SPIN_TEMP" ] && [ -f "$_GUM_SPIN_TEMP" ]; then
        rm -f "$_GUM_SPIN_TEMP" 2> /dev/null || true
        _GUM_SPIN_TEMP=""
    fi

    # Give terminal a moment to clean up
    sleep 0.05s
}

# Update spinner message (restarts spinner with new message)
# Usage: gum_spin_update "New message..."
# Returns: 0 if updated, 1 if no spinner was running
gum_spin_update() {
    gum_require

    local new_title="${1:-Processing...}"

    # Check if spinner is running
    if [ -z "$_GUM_SPIN_PID" ] || ! kill -0 "$_GUM_SPIN_PID" 2> /dev/null; then
        log_trace "Nenhum spinner ativo para atualizar"
        return 1
    fi

    log_trace "Atualizando spinner (PID: $_GUM_SPIN_PID) com nova mensagem: $new_title"

    # Kill current spinner quickly (no cleanup delay)
    if [ -n "$_GUM_SPIN_PID" ] && kill -0 "$_GUM_SPIN_PID" 2> /dev/null; then
        kill -TERM "$_GUM_SPIN_PID" 2> /dev/null || true
        _GUM_SPIN_PID=""
    fi

    # Start new spinner immediately with sleep (use large number for macOS compatibility)
    gum spin --spinner dot --title "$new_title" --spinner.foreground 214 -- sleep 2147483647 &

    _GUM_SPIN_PID=$!
    echo $_GUM_SPIN_PID > "$_GUM_SPIN_TEMP"
    log_trace "Spinner reiniciado (PID: $_GUM_SPIN_PID)"

    # Give spinner a tiny moment to start rendering
    sleep 0.02s

    return 0
}

# Show progress bar (for loops/batches)
# Usage:
#   total=10
#   for i in $(seq 1 $total); do
#       gum_progress $i $total "Processing item $i..."
#       do_work
#   done
gum_progress() {
    gum_require

    local current="$1"
    local total="$2"
    local message="${3:-}"

    local percentage=$((current * 100 / total))
    echo "$percentage" | gum style --foreground 214
    [ -n "$message" ] && echo "$message" | gum style --foreground 246
}

# ============================================================
# Display Functions
# ============================================================

# Show content in pager
# Usage: gum_pager < file.txt
#        echo "content" | gum_pager
gum_pager() {
    gum_require
    gum pager
}

# Format markdown text
# Usage: gum_format < file.md
#        echo "# Title" | gum_format
gum_format() {
    gum_require
    gum format
}

# Style text with colors and formatting
# Usage: gum_style [color] [text]
# Colors: foreground, background, bold, italic, underline, etc
gum_style() {
    gum_require

    local color="$1"
    local text="$2"

    echo "$text" | gum style --foreground "$color"
}

# ============================================================
# High-Level UI Patterns
# ============================================================

# Select from list of items with details
# Usage: gum_select_with_details [header] [items_json]
# items_json format: [{"name": "item1", "description": "desc1"}, ...]
gum_select_with_details() {
    gum_require

    local header="$1"
    local items_json="$2"

    # Create formatted list with name and description
    local formatted_items=()
    while IFS= read -r item; do
        local name=$(echo "$item" | jq -r '.name')
        local desc=$(echo "$item" | jq -r '.description // ""')
        if [ -n "$desc" ]; then
            formatted_items+=("$name - $desc")
        else
            formatted_items+=("$name")
        fi
    done < <(echo "$items_json" | jq -c '.[]')

    local selected=$(gum choose --header "$header" --height 15 "${formatted_items[@]}")

    # Extract just the name (before " - ")
    echo "$selected" | cut -d' ' -f1
}

# Confirm with styled message
# Usage: gum_confirm_styled [title] [message] [confirm_text]
gum_confirm_styled() {
    gum_require

    local title="$1"
    local message="$2"
    local confirm_text="${3:-Sim}"

    # Show styled message
    echo "$title" | gum style --foreground 214 --bold
    echo ""
    echo "$message" | gum style --foreground 246
    echo ""

    gum confirm "$confirm_text" \
        --prompt.foreground="214" \
        --selected.background="214" \
        --selected.foreground="0" \
        --selected.bold \
        --unselected.foreground="245"
}

# Multi-step wizard helper
# Usage:
#   gum_wizard_start "Setup Wizard"
#   step1=$(gum_wizard_step 1 "Nome" "Digite seu nome")
#   step2=$(gum_wizard_step 2 "Email" "Digite seu email")
gum_wizard_start() {
    gum_require

    local title="$1"

    echo "$title" | gum style --foreground 214 --bold --border double --padding "1 2"
    echo ""
}

gum_wizard_step() {
    gum_require

    local step_num="$1"
    local label="$2"
    local prompt="$3"

    echo "Passo $step_num: $label" | gum style --foreground 214
    gum_input "$prompt"
}

# ============================================================
# Table Display (Enhanced)
# ============================================================

# Display CSV table with optional row numbering
# Usage: echo "$csv_data" | gum_table_csv [--numbered] [gum_options...]
# Options:
#   --numbered        Add row numbers (# column) automatically
#   Other options     Passed directly to gum table (e.g., --print, --border, etc.)
#
# Default styling: --print --border rounded --border.foreground 240
#
# Example:
#   csv="Name,Age\nJohn,30\nJane,25"
#   echo "$csv" | gum_table_csv --numbered
gum_table_csv() {
    gum_require

    local numbered=false
    local gum_args=("--print" "--border" "rounded" "--border.foreground" "240")

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --numbered)
                numbered=true
                shift
                ;;
            *)
                gum_args+=("$1")
                shift
                ;;
        esac
    done

    # Read CSV from stdin
    local csv_data=$(cat)

    if [ "$numbered" = true ]; then
        # Add row numbers
        local header=$(echo "$csv_data" | head -n 1)
        local body=$(echo "$csv_data" | tail -n +2)

        # Add # to header
        local numbered_data="#,${header}"$'\n'

        # Add index to each row
        local index=1
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            numbered_data+="${index},${line}"$'\n'
            ((index++))
        done <<< "$body"

        echo "$numbered_data" | gum table "${gum_args[@]}"
    else
        # No numbering, just pass through
        echo "$csv_data" | gum table "${gum_args[@]}"
    fi
}

# ============================================================
# Validation Helpers
# ============================================================

# Get input with validation
# Usage: gum_input_validated [prompt] [validator_command]
# Example: gum_input_validated "Email:" "validate_email"
gum_input_validated() {
    gum_require

    local prompt="$1"
    local validator="$2"

    while true; do
        local value=$(gum_input "$prompt")

        if $validator "$value"; then
            echo "$value"
            return 0
        else
            echo "Valor inválido, tente novamente" | gum style --foreground 196
        fi
    done
}
