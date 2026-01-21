#!/bin/bash
# Redis CLI Update Functions

# Update Redis CLI on macOS
update_redis_macos() {
    if homebrew_update_formula "$REDIS_PKG_MACOS" "Redis CLI"; then
        return 0
    else
        log_info "Redis CLI já está na versão mais recente"
        return 0
    fi
}

# Update Redis CLI on Debian/Ubuntu
update_redis_debian() {
    log_debug "Executando: sudo apt-get install --only-upgrade -y $REDIS_PKG_DEBIAN"

    sudo apt-get update -qq

    if sudo apt-get install --only-upgrade -y $REDIS_PKG_DEBIAN; then
        return 0
    else
        log_info "Redis CLI já está na versão mais recente"
        return 0
    fi
}

# Update Redis CLI on RedHat/CentOS/Fedora
update_redis_redhat() {
    local pkg_manager=$(get_redhat_pkg_manager)
    log_debug "Executando: sudo $pkg_manager upgrade -y $REDIS_PKG_REDHAT"

    if sudo $pkg_manager upgrade -y $REDIS_PKG_REDHAT; then
        return 0
    else
        log_info "Redis CLI já está na versão mais recente"
        return 0
    fi
}

# Update Redis CLI on Arch Linux
update_redis_arch() {
    log_debug "Executando: sudo pacman -Syu --noconfirm $REDIS_PKG_ARCH"

    if sudo pacman -Syu --noconfirm $REDIS_PKG_ARCH; then
        return 0
    else
        log_info "Redis CLI já está na versão mais recente"
        return 0
    fi
}
