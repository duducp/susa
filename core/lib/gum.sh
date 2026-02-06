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

# Show spinner while executing command
# Usage: gum_spin [title] [command...]
# Returns: Command exit code
gum_spin() {
    gum_require

    local title="$1"
    shift
    local command=("$@")

    gum spin --spinner dot --title "$title" -- "${command[@]}"
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

# Display table with gum formatting
# Usage: gum_table [headers] [rows_json]
# headers format: "Header1,Header2,Header3"
# rows_json format: [["val1","val2","val3"], ...]
gum_table() {
    gum_require

    local headers="$1"
    local rows_json="$2"

    # Convert to gum table format
    echo "$headers" | tr ',' '\t'
    echo "$rows_json" | jq -r '.[] | @tsv'
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
