#!/usr/bin/env zsh
# Cursor Common Utilities
# Shared functions used across install, update and uninstall

# Constants
SOFTWARE_NAME="Cursor"
HOMEBREW_PACKAGE="cursor"
CURSOR_BASE_URL="https://api2.cursor.sh/updates/download/golden"

# Get latest version from Homebrew API (works for both macOS and Linux)
get_latest_version() {
    local version=$(curl -fsSL "https://formulae.brew.sh/api/cask/cursor.json" 2> /dev/null | grep -oP '"version":\s*"\K[^"]+' | head -1)

    if [ -z "$version" ] || [ "$version" = "null" ]; then
        log_debug "Não foi possível obter versão da API do Homebrew"
        echo "unknown"
        return 1
    fi

    # Extrair apenas a versão numérica (antes da vírgula se houver)
    # Formato retornado: "2.5.25,hash" -> queremos apenas "2.5.25"
    version=$(echo "$version" | cut -d',' -f1)

    echo "$version"
    return 0
}

# Get installed Cursor version
get_current_version() {
    if check_installation; then
        if is_mac; then
            # Homebrew já retorna versão e commit (ex: 2.5.25,hash)
            homebrew_get_installed_version "$HOMEBREW_PACKAGE"
        else
            # No Linux, tentar obter versão e commit do executável
            if command -v cursor &> /dev/null; then
                # Output esperado: "0.42.3+commit_hash" ou "0.42.3"
                local output=$(cursor --version 2> /dev/null | head -n 1)
                # Extrair versão e commit
                local version_commit=$(echo "$output" | grep -oP '\d+\.\d+\.\d+(\+\w+)?')
                if [ -n "$version_commit" ]; then
                    echo "$version_commit"
                else
                    echo "installed"
                fi
            else
                echo "unknown"
            fi
        fi
    else
        echo "unknown"
    fi
}

# Check if Cursor is installed
check_installation() {
    if is_mac; then
        homebrew_is_installed "$HOMEBREW_PACKAGE"
    else
        # No Linux, verificar se comando está disponível
        command -v cursor &> /dev/null
    fi
}

# Get Cursor configuration paths based on OS and installation method
get_cursor_config_paths() {
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$os_name" in
        darwin)
            CURSOR_CONFIG_DIR="$HOME/Library/Application Support/Cursor"
            CURSOR_USER_DIR="$HOME/.cursor"
            ;;
        linux)
            CURSOR_CONFIG_DIR="$HOME/.config/Cursor"
            CURSOR_USER_DIR="$HOME/.cursor"
            log_debug "Usando diretório padrão: $CURSOR_CONFIG_DIR"
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    return 0
}

# Show additional Cursor-specific information
show_additional_info() {
    if ! check_installation; then
        return
    fi

    # Show configuration directory
    if get_cursor_config_paths; then
        if [ -d "$CURSOR_CONFIG_DIR" ]; then
            log_output "  ${CYAN}Configurações:${NC} $CURSOR_CONFIG_DIR"
        fi
    fi

    # Check installation method
    if is_mac; then
        if homebrew_is_installed "$HOMEBREW_PACKAGE"; then
            log_output "  ${CYAN}Método:${NC} Homebrew"
        fi
    else
        if command -v cursor &> /dev/null; then
            log_output "  ${CYAN}Método:${NC} AppImage/Manual"
        fi
    fi
}
