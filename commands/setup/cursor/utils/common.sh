#!/usr/bin/env zsh
# Cursor Common Utilities
# Shared functions used across install, update and uninstall

# Constants
SOFTWARE_NAME="Cursor"
HOMEBREW_PACKAGE="cursor"
FLATPAK_APP_ID="com.cursor.Cursor"
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
            homebrew_get_installed_version "$HOMEBREW_PACKAGE"
        else
            # No Linux, tentar obter versão do executável
            if command -v cursor &> /dev/null; then
                # Extrair versão do output de --version
                # Formato esperado: "0.42.3" ou similar
                local version=$(cursor --version 2> /dev/null | grep -oP '\d+\.\d+\.\d+' | head -n 1)
                if [ -n "$version" ]; then
                    echo "$version"
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
