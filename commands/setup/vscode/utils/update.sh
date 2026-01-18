#!/bin/bash
# VSCode Update Utilities
# Functions for updating VS Code on different platforms

# Update VS Code on Debian/Ubuntu
update_vscode_debian() {
    log_info "Atualizando VS Code via apt..."
    sudo apt-get update > /dev/null 2>&1
    sudo apt-get install --only-upgrade -y $VSCODE_DEB_PACKAGE > /dev/null 2>&1
}

# Update VS Code on RHEL/Fedora/CentOS
update_vscode_rhel() {
    log_info "Atualizando VS Code via dnf/yum..."
    if command -v dnf &> /dev/null; then
        sudo dnf upgrade -y $VSCODE_RPM_PACKAGE > /dev/null 2>&1
    else
        sudo yum update -y $VSCODE_RPM_PACKAGE > /dev/null 2>&1
    fi
}

# Update VS Code on Arch Linux
update_vscode_arch() {
    log_info "Atualizando VS Code via pacman/AUR..."
    if command -v yay &> /dev/null; then
        yay -Syu --noconfirm $VSCODE_ARCH_AUR > /dev/null 2>&1
    elif command -v paru &> /dev/null; then
        paru -Syu --noconfirm $VSCODE_ARCH_AUR > /dev/null 2>&1
    else
        sudo pacman -Syu --noconfirm $VSCODE_ARCH_COMMUNITY > /dev/null 2>&1
    fi
}
