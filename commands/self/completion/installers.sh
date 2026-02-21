#!/usr/bin/env zsh

# ============================================================
# Completion Installer Functions
# ============================================================

# Install completion for Bash
install_bash_completion() {
    # Check if already installed
    if is_completion_installed "bash"; then
        return 2 # Signal already installed
    fi

    local completion_dir=$(get_completion_dir_path "bash")
    local completion_file=$(get_completion_file_path "bash")

    # Create directory if it doesn't exist
    mkdir -p "$completion_dir" 2> /dev/null || return 1

    # Generate and save the script
    generate_bash_completion > "$completion_file" 2> /dev/null || return 1
    chmod +x "$completion_file" 2> /dev/null || return 1

    return 0 # Success
}

# Install completion for Zsh
install_zsh_completion() {
    # Check if already installed
    if is_completion_installed "zsh"; then
        return 2 # Signal already installed
    fi

    local completion_dir=$(get_completion_dir_path "zsh")
    local completion_file=$(get_completion_file_path "zsh")

    # Create directory if it doesn't exist
    mkdir -p "$completion_dir" 2> /dev/null || return 1

    # Generate and save the script
    generate_zsh_completion > "$completion_file" 2> /dev/null || return 1
    chmod +x "$completion_file" 2> /dev/null || return 1

    # Clear zsh completion cache
    rm -f ~/.zcompdump* 2> /dev/null || true

    return 0 # Success
}

# Install completion for Fish
install_fish_completion() {
    # Check if already installed
    if is_completion_installed "fish"; then
        return 2 # Signal already installed
    fi

    local completion_dir=$(get_completion_dir_path "fish")
    local completion_file=$(get_completion_file_path "fish")

    # Create directory if it doesn't exist
    mkdir -p "$completion_dir" 2> /dev/null || return 1

    # Generate and save the script
    generate_fish_completion > "$completion_file" 2> /dev/null || return 1
    chmod +x "$completion_file" 2> /dev/null || return 1

    return 0 # Success
}
