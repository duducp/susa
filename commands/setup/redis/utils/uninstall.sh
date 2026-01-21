#!/bin/bash
# Redis CLI Uninstall Functions

# Uninstall Redis CLI on macOS
uninstall_redis_macos() {
    if ! homebrew_uninstall_formula "redis" "Redis CLI"; then
        log_error "Falha ao desinstalar via Homebrew"
        return 1
    fi

    return 0
}

# Uninstall Redis CLI on Debian/Ubuntu
uninstall_redis_debian() {
    log_debug "Executando: sudo apt-get remove -y redis-tools"

    if ! sudo apt-get remove -y redis-tools; then
        log_error "Falha ao desinstalar Redis CLI"
        return 1
    fi

    sudo apt-get autoremove -y
    return 0
}

# Uninstall Redis CLI on RedHat/CentOS/Fedora
uninstall_redis_redhat() {
    local pkg_manager=$(get_redhat_pkg_manager)
    log_debug "Executando: sudo $pkg_manager remove -y redis"

    if ! sudo $pkg_manager remove -y redis; then
        log_error "Falha ao desinstalar Redis CLI"
        return 1
    fi

    return 0
}

# Uninstall Redis CLI on Arch Linux
uninstall_redis_arch() {
    log_debug "Executando: sudo pacman -R --noconfirm redis"

    if ! sudo pacman -R --noconfirm redis; then
        log_error "Falha ao desinstalar Redis CLI"
        return 1
    fi

    return 0
}
