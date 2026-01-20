#!/bin/bash
# MySQL Client Uninstall Functions

# Uninstall MySQL client on macOS using Homebrew
uninstall_mysql_macos() {
    log_info "Desinstalando via Homebrew..."
    if homebrew_is_available; then
        if homebrew_uninstall_formula "$MYSQL_CLIENT_PKG_HOMEBREW" "MySQL Client"; then
            return 0
        else
            log_error "Falha ao desinstalar via Homebrew"
            return 1
        fi
    else
        log_error "Homebrew não está disponível"
        return 1
    fi
}

# Uninstall MySQL client on Debian/Ubuntu
uninstall_mysql_debian() {
    log_info "Desinstalando via apt..."
    sudo apt-get remove -y $MYSQL_CLIENT_PKG_DEBIAN || {
        log_error "Falha ao desinstalar MySQL Client"
        return 1
    }
    sudo apt-get autoremove -y
    return 0
}

# Uninstall MySQL client on RedHat/CentOS/Fedora
uninstall_mysql_redhat() {
    local pkg_manager=$(get_redhat_pkg_manager)
    log_info "Desinstalando via $pkg_manager..."
    sudo $pkg_manager remove -y $MYSQL_CLIENT_PKG_REDHAT || {
        log_error "Falha ao desinstalar MySQL Client"
        return 1
    }
    return 0
}

# Uninstall MySQL client on Arch Linux
uninstall_mysql_arch() {
    log_info "Desinstalando via pacman..."
    sudo pacman -R --noconfirm $MYSQL_CLIENT_PKG_ARCH || {
        log_error "Falha ao desinstalar MySQL Client"
        return 1
    }
    return 0
}
