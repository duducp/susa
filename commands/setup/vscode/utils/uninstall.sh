#!/bin/bash
# VSCode Uninstall Utilities
# Functions for uninstalling VS Code on different platforms

# Uninstall VS Code on Debian/Ubuntu
uninstall_vscode_debian() {
    log_info "Removendo VS Code via apt..."
    sudo apt-get purge -y $VSCODE_DEB_PACKAGE > /dev/null 2>&1
    sudo apt-get autoremove -y > /dev/null 2>&1

    # Remove repository
    sudo rm -f /etc/apt/sources.list.d/vscode.list
    sudo rm -f /etc/apt/trusted.gpg.d/microsoft.gpg
}

# Uninstall VS Code on RHEL/Fedora/CentOS
uninstall_vscode_rhel() {
    log_info "Removendo VS Code via dnf/yum..."
    if command -v dnf &> /dev/null; then
        sudo dnf remove -y code > /dev/null 2>&1
    else
        sudo yum remove -y code > /dev/null 2>&1
    fi

    # Remove repository
    sudo rm -f /etc/yum.repos.d/vscode.repo
}

# Uninstall VS Code on Arch Linux
uninstall_vscode_arch() {
    log_info "Removendo VS Code via pacman..."
    if command -v yay &> /dev/null; then
        yay -Rns --noconfirm $VSCODE_ARCH_AUR > /dev/null 2>&1 || sudo pacman -Rns --noconfirm $VSCODE_ARCH_COMMUNITY > /dev/null 2>&1
    elif command -v paru &> /dev/null; then
        paru -Rns --noconfirm $VSCODE_ARCH_AUR > /dev/null 2>&1 || sudo pacman -Rns --noconfirm $VSCODE_ARCH_COMMUNITY > /dev/null 2>&1
    else
        sudo pacman -Rns --noconfirm $VSCODE_ARCH_COMMUNITY > /dev/null 2>&1
    fi
}

# Remove VS Code configurations and extensions
remove_vscode_configs() {
    local os_name="$1"

    log_info "Removendo configurações e extensões..."

    case "$os_name" in
        darwin)
            rm -rf "$HOME/Library/Application Support/Code" 2> /dev/null || true
            log_debug "Configurações removidas: ~/Library/Application Support/Code"
            rm -rf "$HOME/.vscode" 2> /dev/null || true
            log_debug "Extensões removidas: ~/.vscode"
            rm -rf "$HOME/Library/Caches/com.microsoft.VSCode" 2> /dev/null || true
            log_debug "Cache removido"
            ;;
        linux)
            rm -rf "$HOME/.config/Code" 2> /dev/null || true
            log_debug "Configurações removidas: ~/.config/Code"
            rm -rf "$HOME/.vscode" 2> /dev/null || true
            log_debug "Extensões removidas: ~/.vscode"
            rm -rf "$HOME/.cache/vscode" 2> /dev/null || true
            log_debug "Cache removido: ~/.cache/vscode"
            ;;
    esac

    log_success "Configurações e extensões removidas"
}
