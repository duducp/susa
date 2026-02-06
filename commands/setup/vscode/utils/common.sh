#!/usr/bin/env zsh
# VSCode Common Utilities
# Shared functions used across install, update and uninstall

# Source libraries
source "$LIB_DIR/homebrew.sh"
source "$LIB_DIR/flatpak.sh"
source "$LIB_DIR/snap.sh"

# Constants
VSCODE_NAME="Visual Studio Code"
VSCODE_REPO="microsoft/vscode"
VSCODE_BIN_NAME="code"
VSCODE_HOMEBREW_CASK="visual-studio-code"
VSCODE_APT_KEY_URL="https://packages.microsoft.com/keys/microsoft.asc"
VSCODE_APT_REPO="https://packages.microsoft.com/repos/code"
VSCODE_RPM_KEY_URL="https://packages.microsoft.com/keys/microsoft.asc"
VSCODE_RPM_REPO_URL="https://packages.microsoft.com/yumrepos/vscode"
VSCODE_DEB_PACKAGE="code"
VSCODE_RPM_PACKAGE="code"
VSCODE_ARCH_AUR="visual-studio-code-bin"
VSCODE_ARCH_COMMUNITY="code"
FLATPAK_APP_ID="com.visualstudio.code"
SNAP_PACKAGE_NAME="code"

# Get latest version from GitHub
get_latest_version() {
    local version=$(github_get_latest_version "$VSCODE_REPO" 2> /dev/null)

    if [ -n "$version" ] && [ "$version" != "null" ]; then
        echo "$version"
    else
        echo "desconhecida"
    fi
}

# Get installed VS Code version
get_current_version() {
    if check_installation; then
        local version=$($VSCODE_BIN_NAME --version 2> /dev/null | head -1 || echo "desconhecida")
        if [ "$version" != "desconhecida" ]; then
            echo "$version"
        fi
    else
        echo "desconhecida"
    fi
}

# Check if VS Code is installed via alternative methods
check_installation_alternative() {
    # Check if code command is available
    if command -v code &> /dev/null; then
        log_debug "VS Code encontrado no PATH: $(command -v code)"
        return 0
    fi

    # Check common installation directories
    local common_dirs=(
        "/usr/bin/code"
        "/usr/local/bin/code"
        "$HOME/.local/bin/code"
    )

    for dir in "${common_dirs[@]}"; do
        if [ -x "$dir" ]; then
            log_debug "VS Code encontrado em: $dir"
            return 0
        fi
    done

    return 1
}

# Check if VS Code is installed
check_installation() {
    if is_mac; then
        # On Mac, check Homebrew first, then command
        if homebrew_is_installed "$VSCODE_HOMEBREW_CASK"; then
            return 0
        fi
        command -v $VSCODE_BIN_NAME &> /dev/null
    else
        # On Linux, check Flatpak, Snap, then alternatives
        if flatpak_is_installed "$FLATPAK_APP_ID"; then
            return 0
        fi

        if snap_is_installed "$SNAP_PACKAGE_NAME"; then
            return 0
        fi

        check_installation_alternative
    fi
}

# Show additional VS Code-specific information
show_additional_info() {
    if ! check_installation; then
        return
    fi

    # Count installed extensions
    if command -v code &> /dev/null; then
        local extensions=$(code --list-extensions 2> /dev/null | wc -l | xargs)
        if [ "$extensions" != "0" ]; then
            log_output "  ${CYAN}Extensões:${NC} $extensions instaladas"
        fi
    fi

    # Check installation method
    if is_mac; then
        if homebrew_is_installed "$VSCODE_HOMEBREW_CASK"; then
            log_output "  ${CYAN}Método:${NC} Homebrew"
        fi
    else
        if flatpak_is_installed "$FLATPAK_APP_ID"; then
            log_output "  ${CYAN}Método:${NC} Flatpak"
        elif snap_is_installed "$SNAP_PACKAGE_NAME"; then
            log_output "  ${CYAN}Método:${NC} Snap"
        fi
    fi
}

# Get VSCode configuration paths based on OS and installation method
get_vscode_config_paths() {
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$os_name" in
        darwin)
            VSCODE_CONFIG_DIR="$HOME/Library/Application Support/Code"
            VSCODE_USER_DIR="$HOME/.vscode"
            ;;
        linux)
            # Check if VS Code is installed via Snap
            if snap_is_installed "$SNAP_PACKAGE_NAME"; then
                # Snap installations store data in ~/snap/app-name/
                local snap_base="$HOME/snap/code"

                # Try common/ first (persistent data), then current/ (latest revision)
                if [ -d "$snap_base/common/.config/Code" ]; then
                    VSCODE_CONFIG_DIR="$snap_base/common/.config/Code"
                elif [ -d "$snap_base/current/.config/Code" ]; then
                    VSCODE_CONFIG_DIR="$snap_base/current/.config/Code"
                else
                    VSCODE_CONFIG_DIR="$snap_base/common/.config/Code"
                fi

                VSCODE_USER_DIR="$HOME/.vscode"

                log_debug "Usando diretório Snap: $VSCODE_CONFIG_DIR"
            # Check if VS Code is installed via Flatpak
            elif flatpak_is_installed "$FLATPAK_APP_ID"; then
                # Flatpak installations store data in ~/.var/app/
                VSCODE_CONFIG_DIR="$HOME/.var/app/$FLATPAK_APP_ID/config/Code"
                VSCODE_USER_DIR="$HOME/.var/app/$FLATPAK_APP_ID/data/vscode"

                log_debug "Usando diretório Flatpak: $VSCODE_CONFIG_DIR"
            else
                # Standard Linux installation
                VSCODE_CONFIG_DIR="$HOME/.config/Code"
                VSCODE_USER_DIR="$HOME/.vscode"

                log_debug "Usando diretório padrão: $VSCODE_CONFIG_DIR"
            fi
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    return 0
}
