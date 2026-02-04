#!/bin/bash

# Constants
TOOLBOX_NAME="JetBrains Toolbox"
TOOLBOX_BIN_NAME="jetbrains-toolbox"
TOOLBOX_GITHUB_REPO="jetbrains/toolbox-app"
TOOLBOX_API_URL="https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release"
TOOLBOX_API_MAX_TIME=10
TOOLBOX_API_CONNECT_TIMEOUT=5
TOOLBOX_LINUX_INSTALL_DIR="$HOME/.local/share/JetBrains/Toolbox"
TOOLBOX_MAC_INSTALL_DIR="$HOME/Library/Application Support/JetBrains/Toolbox"
TOOLBOX_LOCAL_BIN_DIR="$HOME/.local/bin"
LOCAL_BIN_DIR="$HOME/.local/bin"

# Check if JetBrains Toolbox is installed
check_installation() {
    command -v jetbrains-toolbox &> /dev/null || [ -f "$HOME/.local/bin/jetbrains-toolbox" ]
}

# Get current installed version
get_current_version() {
    local install_dir
    if is_mac; then
        install_dir="$TOOLBOX_MAC_INSTALL_DIR"
    else
        install_dir="$TOOLBOX_LINUX_INSTALL_DIR"
    fi

    local version_file="$install_dir/.version"

    if [ -f "$version_file" ]; then
        cat "$version_file"
    else
        echo "desconhecida"
    fi
}

# Get latest version from JetBrains API
get_latest_version() {
    local api_response=$(curl -s --max-time "$TOOLBOX_API_MAX_TIME" --connect-timeout "$TOOLBOX_API_CONNECT_TIMEOUT" "$TOOLBOX_API_URL" 2> /dev/null)

    if [ -z "$api_response" ]; then
        log_error "Não foi possível obter a versão mais recente do JetBrains Toolbox" >&2
        log_error "Verifique sua conexão com a internet e tente novamente" >&2
        return 1
    fi

    # Extract version (e.g., "3.2.0.65851") - using sed for better compatibility
    local latest_version=$(echo "$api_response" | sed -n 's/.*"version":"\([^"]*\)".*/\1/p' | head -1)

    if [ -n "$latest_version" ]; then
        log_debug "Versão obtida via API JetBrains: $latest_version" >&2
        echo "$latest_version"
        return 0
    fi

    log_error "Não foi possível obter a versão mais recente do JetBrains Toolbox" >&2
    log_error "Verifique sua conexão com a internet e tente novamente" >&2
    return 1
}

# Get download URL from API based on OS and architecture
get_download_url() {
    local os_arch="$1"
    local os_name="${os_arch%:*}"
    local arch="${os_arch#*:}"

    local api_response=$(curl -s --max-time "$TOOLBOX_API_MAX_TIME" --connect-timeout "$TOOLBOX_API_CONNECT_TIMEOUT" "$TOOLBOX_API_URL" 2> /dev/null)

    if [ -z "$api_response" ]; then
        log_error "Não foi possível obter informações de download" >&2
        return 1
    fi

    local download_key
    if [ "$os_name" = "linux" ]; then
        if [ "$arch" = "arm64" ]; then
            download_key="linuxARM64"
        else
            download_key="linux"
        fi
    elif [ "$os_name" = "mac" ]; then
        if [ "$arch" = "arm64" ]; then
            download_key="macM1"
        else
            download_key="mac"
        fi
    else
        log_error "Sistema operacional não suportado" >&2
        return 1
    fi

    local download_url=$(echo "$api_response" | sed -n "s/.*\"$download_key\":{[^}]*\"link\":\"\\([^\"]*\\)\".*/\\1/p")

    if [ -n "$download_url" ]; then
        log_debug "URL de download: $download_url" >&2
        echo "$download_url"
        return 0
    fi

    log_error "Não foi possível obter URL de download para $os_name $arch" >&2
    return 1
}

# Detect OS and architecture
detect_os_and_arch() {
    local os_name
    if is_mac; then
        os_name="mac"
    else
        os_name="linux"
    fi

    local arch=$(uname -m)

    case "$arch" in
        x86_64) arch="x64" ;;
        aarch64 | arm64) arch="arm64" ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    echo "${os_name}:${arch}"
}

# Get installation directory based on OS
get_install_dir() {
    if is_mac; then
        echo "$HOME/Library/Application Support/JetBrains/Toolbox"
    else
        echo "$HOME/.local/share/JetBrains/Toolbox"
    fi
}

# Get binary location
get_binary_location() {
    if is_mac; then
        echo "/Applications/JetBrains Toolbox.app"
    else
        echo "$LOCAL_BIN_DIR/jetbrains-toolbox"
    fi
}

# Create desktop entry for Linux
create_desktop_entry() {
    local desktop_file="$HOME/.local/share/applications/jetbrains-toolbox.desktop"
    local icon_path="$HOME/.local/share/JetBrains/Toolbox/toolbox.svg"

    mkdir -p "$(dirname "$desktop_file")"
    mkdir -p "$(dirname "$icon_path")"

    # Download icon if not exists
    if [ ! -f "$icon_path" ]; then
        curl -s -o "$icon_path" "https://resources.jetbrains.com/storage/products/toolbox/img/meta/toolbox_logo_300x300.png" 2> /dev/null || log_debug "Falha ao baixar ícone"
    fi

    local toolbox_bin="$LOCAL_BIN_DIR/jetbrains-toolbox"
    cat > "$desktop_file" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=JetBrains Toolbox
Icon=$icon_path
Exec=$toolbox_bin
Comment=JetBrains IDEs Manager
Categories=Development;IDE;
Terminal=false
StartupWMClass=jetbrains-toolbox
StartupNotify=false
EOF

    chmod +x "$desktop_file"
    log_debug "Atalho criado: $desktop_file"
}
