#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ============================================================
# Git Helper Functions
# ============================================================
# Functions for Git operations and SSH access checks

# Checks if git is installed
ensure_git_installed() {
    if ! command -v git &> /dev/null; then
        log_error "Git not found. Install git first."
        return 1
    fi
    return 0
}

# Checks if user has SSH access to GitHub configured
has_github_ssh_access() {
    # Check if SSH key exists
    if [ ! -f "$HOME/.ssh/id_rsa" ] && [ ! -f "$HOME/.ssh/id_ed25519" ]; then
        return 1
    fi

    # Test SSH connection to GitHub (timeout after 3 seconds)
    if timeout 3 ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        return 0
    fi

    return 1
}

# Checks if user has SSH access to GitLab configured
has_gitlab_ssh_access() {
    # Check if SSH key exists
    if [ ! -f "$HOME/.ssh/id_rsa" ] && [ ! -f "$HOME/.ssh/id_ed25519" ]; then
        return 1
    fi

    # Test SSH connection to GitLab (timeout after 3 seconds)
    if timeout 3 ssh -T git@gitlab.com 2>&1 | grep -q "Welcome to GitLab"; then
        return 0
    fi

    return 1
}

# Checks if user has SSH access to Bitbucket configured
has_bitbucket_ssh_access() {
    # Check if SSH key exists
    if [ ! -f "$HOME/.ssh/id_rsa" ] && [ ! -f "$HOME/.ssh/id_ed25519" ]; then
        return 1
    fi

    # Test SSH connection to Bitbucket (timeout after 3 seconds)
    if timeout 3 ssh -T git@bitbucket.org 2>&1 | grep -q "authenticated"; then
        return 0
    fi

    return 1
}

# Detects Git provider from URL
detect_git_provider() {
    local url="$1"

    if [[ "$url" =~ github\.com ]]; then
        echo "github"
    elif [[ "$url" =~ gitlab\.com ]]; then
        echo "gitlab"
    elif [[ "$url" =~ bitbucket\.org ]]; then
        echo "bitbucket"
    else
        echo "unknown"
    fi
}

# Validates if repository is accessible
validate_repo_access() {
    local url="$1"

    log_debug "Validando acesso ao repositório..."

    # Use git ls-remote to check if we can access the repo
    if git ls-remote "$url" HEAD &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Clones plugin from a Git repository
clone_plugin() {
    local url="$1"
    local dest_dir="$2"
    local error_output

    # Captura a saída de erro do git clone, mas oculta do usuário
    error_output=$(git clone "$url" "$dest_dir" 2>&1)
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        # Remove .git to save space
        rm -rf "$dest_dir/.git"
        return 0
    else
        log_error "Falha ao clonar o repositório"
        log_debug "URL: $url"
        log_debug "Destino: $dest_dir"
        log_debug "Detalhes do erro:"
        log_debug "$error_output"
        return 1
    fi
}

# Pulls latest changes from Git repository
pull_plugin() {
    local plugin_dir="$1"
    local error_output

    cd "$plugin_dir" || return 1

    # Captura a saída de erro do git pull, mas oculta do usuário
    error_output=$(git pull 2>&1)
    local exit_code=$?

    cd - > /dev/null || return 1

    if [ $exit_code -eq 0 ]; then
        return 0
    else
        log_error "Falha ao atualizar o repositório"
        log_debug "Diretório: $plugin_dir"
        log_debug "Detalhes do erro:"
        log_debug "$error_output"
        return 1
    fi
}
