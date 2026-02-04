#!/bin/bash
# Poetry Common Utilities
# Shared functions used across install, update and uninstall

# Constants
POETRY_NAME="Poetry"
POETRY_REPO="python-poetry/poetry"
POETRY_BIN_NAME="poetry"
POETRY_INSTALL_URL="https://install.python-poetry.org"
POETRY_HOME="$HOME/.local/share/pypoetry"

# Get latest version
get_latest_version() {
    github_get_latest_version "$POETRY_REPO"
}

# Get installed Poetry version
get_current_version() {
    if check_installation; then
        $POETRY_BIN_NAME --version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Check if Poetry is installed
check_installation() {
    command -v $POETRY_BIN_NAME &> /dev/null
}

# Show additional Poetry-specific information
show_additional_info() {
    if ! check_installation; then
        return
    fi

    # Check Poetry configuration
    local venv_in_project=$(poetry config virtualenvs.in-project 2> /dev/null)
    if [ -n "$venv_in_project" ]; then
        log_output "  ${CYAN}Virtualenvs in-project:${NC} $venv_in_project"
    fi

    # Count virtual environments
    local venvs=$(poetry env list 2> /dev/null | wc -l | xargs)
    if [ "$venvs" != "0" ]; then
        log_output "  ${CYAN}Ambientes virtuais:${NC} $venvs configurados"
    fi

    # Check if Poetry self plugins are installed
    local plugins=$(poetry self show plugins 2> /dev/null | grep -v "^$" | wc -l | xargs)
    if [ "$plugins" != "0" ]; then
        log_output "  ${CYAN}Plugins:${NC} $plugins instalados"
    fi
}

# Configure shell to use Poetry
configure_shell() {
    local poetry_home="$1"
    local shell_config=$(detect_shell_config)

    log_debug "Arquivo de configuração: $shell_config"

    # Check if Poetry is already configured
    if grep -q "POETRY_HOME\|poetry/bin" "$shell_config" 2> /dev/null; then
        log_debug "Poetry já configurado em $shell_config"
        return 0
    fi

    log_debug "Configurando $shell_config..."

    echo "" >> "$shell_config"
    echo "# Poetry (Python dependency manager)" >> "$shell_config"
    echo "export POETRY_HOME=\"$poetry_home\"" >> "$shell_config"
    echo "export PATH=\"\$POETRY_HOME/bin:\$PATH\"" >> "$shell_config"

    log_debug "Configuração adicionada ao shell"
}

# Setup Poetry environment for current session
setup_poetry_environment() {
    local poetry_home="$1"

    export POETRY_HOME="$poetry_home"
    export PATH="$POETRY_HOME/bin:$PATH"

    log_debug "Ambiente configurado para sessão atual"
    log_debug "POETRY_HOME: $POETRY_HOME"
    log_debug "PATH atualizado com: $POETRY_HOME/bin"
}

# Remove Poetry shell configurations
remove_shell_config() {
    local shell_config=$(detect_shell_config)

    if [ -f "$shell_config" ] && grep -q "POETRY_HOME\|poetry/bin" "$shell_config" 2> /dev/null; then
        local backup_file="${shell_config}.backup.$(date +%Y%m%d%H%M%S)"

        # Create backup
        cp "$shell_config" "$backup_file"
        log_debug "Backup criado: $backup_file"

        # Remove Poetry lines
        sed -i.tmp '/# Poetry (Python dependency manager)/d' "$shell_config"
        sed -i.tmp '/POETRY_HOME/d' "$shell_config"
        sed -i.tmp '/poetry\/bin/d' "$shell_config"
        rm -f "${shell_config}.tmp"

        log_debug "Configurações removidas"
    else
        log_debug "Nenhuma configuração encontrada em $shell_config"
    fi
}

# Remove Poetry cache and config
remove_poetry_data() {
    rm -rf "$HOME/.cache/pypoetry" 2> /dev/null || true
    log_debug "Cache removido: ~/.cache/pypoetry"

    rm -rf "$HOME/.config/pypoetry" 2> /dev/null || true
    log_debug "Configurações removidas: ~/.config/pypoetry"

    log_success "Cache e configurações removidos"
}
