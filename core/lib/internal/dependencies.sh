#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# --- Command Existence Checks ---

# Check if a command exists in the system
# Usage:
#   command_exists "command_name"
# Example:
#   if command_exists "curl"; then
#       echo "curl is installed"
#   fi
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if multiple dependencies are installed
# Returns 0 if all are installed, 1 otherwise
# Usage:
#   check_dependencies "curl" "jq" "git"
# Example:
#   if ! check_dependencies "curl" "jq" "git"; then
#       echo "Some dependencies are missing."
#   fi
check_dependencies() {
    local missing=()

    for cmd in "$@"; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Dependências faltando: ${missing[*]}"
        return 1
    fi

    return 0
}

# --- Pip3 Helper Function ---

# Ensure pip3 is installed. If not, try installing.
ensure_pip3_installed() {
    if command -v pip3 &> /dev/null; then
        return 0
    fi

    log_warning "pip3 não encontrado. Tentando instalar python3-pip..."

    if command -v apt-get &> /dev/null; then
        wait_for_apt_lock || return 1
        sudo apt-get update -qq > /dev/null 2>&1
        sudo apt-get install -y python3-pip > /dev/null 2>&1
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y python3-pip > /dev/null 2>&1
    elif command -v yum &> /dev/null; then
        sudo yum install -y python3-pip > /dev/null 2>&1
    else
        log_error "Gerenciador de pacotes não suportado para instalação do pip3"
        return 1
    fi

    if ! command -v pip3 &> /dev/null; then
        log_error "Falha ao instalar o pip3. Instale manualmente."
        return 1
    fi

    log_success "pip3 instalado com sucesso."
    return 0
}
