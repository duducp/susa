#!/bin/bash
# DBeaver Common Utilities
# Shared functions used across install, update and uninstall

# Constants
DBEAVER_NAME="DBeaver"
DBEAVER_BIN_NAME="dbeaver"
DBEAVER_GITHUB_REPO="dbeaver/dbeaver"
DBEAVER_INSTALL_DIR="/opt/dbeaver"
DBEAVER_PACKAGE_NAME="dbeaver-ce"
DBEAVER_HOMEBREW_CASK="dbeaver-community"
DBEAVER_APT_REPO="https://dbeaver.io/debs/dbeaver-ce"
DBEAVER_APT_KEY_URL="https://dbeaver.io/debs/dbeaver.gpg.key"
FLATPAK_APP_ID="io.dbeaver.DBeaverCommunity"
SNAP_PACKAGE_NAME="dbeaver-ce"

# Get latest version
get_latest_version() {
    if is_mac; then
        homebrew_get_latest_version "$DBEAVER_HOMEBREW_CASK"
    else
        flatpak_get_latest_version "$FLATPAK_APP_ID"
    fi
}

# Get installed DBeaver version
get_current_version() {
    if check_installation; then
        if is_mac; then
            homebrew_get_installed_version "$DBEAVER_HOMEBREW_CASK"
        else
            flatpak_get_installed_version "$FLATPAK_APP_ID"
        fi
    else
        echo "desconhecida"
    fi
}

# Check if DBeaver is installed via alternative methods
# (binary in PATH, installation directory, etc.)
check_installation_alternative() {
    # Check if dbeaver command is available
    if command -v dbeaver &> /dev/null; then
        log_debug "DBeaver encontrado no PATH: $(command -v dbeaver)"
        return 0
    fi

    # Check if installed in /opt/dbeaver
    if [ -d "$DBEAVER_INSTALL_DIR" ] && [ -x "$DBEAVER_INSTALL_DIR/dbeaver" ]; then
        log_debug "DBeaver encontrado em: $DBEAVER_INSTALL_DIR"
        return 0
    fi

    # Check common installation directories on Linux
    local common_dirs=(
        "/usr/bin/dbeaver"
        "/usr/local/bin/dbeaver"
        "$HOME/.local/bin/dbeaver"
    )

    for dir in "${common_dirs[@]}"; do
        if [ -x "$dir" ]; then
            log_debug "DBeaver encontrado em: $dir"
            return 0
        fi
    done

    # Not found via alternative methods
    return 1
}

# Check if DBeaver is installed
check_installation() {
    if is_mac; then
        homebrew_is_installed "$DBEAVER_HOMEBREW_CASK"
    else
        # First check Flatpak installation
        if flatpak_is_installed "$FLATPAK_APP_ID"; then
            return 0
        fi

        # Then check Snap installation
        if snap_is_installed "$SNAP_PACKAGE_NAME"; then
            return 0
        fi

        # If not found via Flatpak or Snap, check alternative methods
        check_installation_alternative
    fi
}

# Get DBeaver configuration paths based on OS and installation method
get_dbeaver_config_paths() {
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$os_name" in
        darwin)
            DBEAVER_CONFIG_DIR="$HOME/Library/DBeaverData/workspace6"
            DBEAVER_SCRIPTS_DIR="$HOME/Library/DBeaverData/workspace6/scripts"
            DBEAVER_CONNECTIONS_FILE="$HOME/Library/DBeaverData/workspace6/.metadata/.plugins/org.jkiss.dbeaver.core/data-sources.json"
            ;;
        linux)
            # Check if DBeaver is installed via Snap
            if snap_is_installed "$SNAP_PACKAGE_NAME"; then
                # Snap installations store data in ~/snap/app-name/
                local snap_base="$HOME/snap/dbeaver-ce"

                # Try common/ first (persistent data), then current/ (latest revision)
                if [ -d "$snap_base/common/.local/share/DBeaverData/workspace6" ]; then
                    DBEAVER_CONFIG_DIR="$snap_base/common/.local/share/DBeaverData/workspace6"
                elif [ -d "$snap_base/current/.local/share/DBeaverData/workspace6" ]; then
                    DBEAVER_CONFIG_DIR="$snap_base/current/.local/share/DBeaverData/workspace6"
                else
                    DBEAVER_CONFIG_DIR="$snap_base/common/.local/share/DBeaverData/workspace6"
                fi

                DBEAVER_SCRIPTS_DIR="$DBEAVER_CONFIG_DIR/scripts"
                DBEAVER_CONNECTIONS_FILE="$DBEAVER_CONFIG_DIR/.metadata/.plugins/org.jkiss.dbeaver.core/data-sources.json"

                log_debug "Usando diretório Snap: $DBEAVER_CONFIG_DIR"
            # Check if DBeaver is installed via Flatpak
            elif flatpak_is_installed "$FLATPAK_APP_ID"; then
                # Flatpak installations store data in ~/.var/app/
                DBEAVER_CONFIG_DIR="$HOME/.var/app/$FLATPAK_APP_ID/data/DBeaverData/workspace6"
                DBEAVER_SCRIPTS_DIR="$DBEAVER_CONFIG_DIR/scripts"
                DBEAVER_CONNECTIONS_FILE="$DBEAVER_CONFIG_DIR/.metadata/.plugins/org.jkiss.dbeaver.core/data-sources.json"

                log_debug "Usando diretório Flatpak: $DBEAVER_CONFIG_DIR"
            else
                # Standard Linux installation
                DBEAVER_CONFIG_DIR="$HOME/.local/share/DBeaverData/workspace6"
                DBEAVER_SCRIPTS_DIR="$HOME/.local/share/DBeaverData/workspace6/scripts"
                DBEAVER_CONNECTIONS_FILE="$HOME/.local/share/DBeaverData/workspace6/.metadata/.plugins/org.jkiss.dbeaver.core/data-sources.json"

                log_debug "Usando diretório padrão: $DBEAVER_CONFIG_DIR"
            fi
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    return 0
}
