#!/usr/bin/env zsh
# PostgreSQL Client Uninstall Functions

# Uninstall PostgreSQL client on macOS using Homebrew
uninstall_postgres_macos() {
    log_info "Desinstalando via Homebrew..."
    if homebrew_is_available; then
        if homebrew_uninstall_formula "$POSTGRES_CLIENT_PKG_HOMEBREW" "PostgreSQL Client"; then
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

# Uninstall PostgreSQL client on Debian/Ubuntu
uninstall_postgres_debian() {
    log_info "Desinstalando via apt..."
    sudo apt-get remove -y $POSTGRES_CLIENT_PKG_DEBIAN || {
        log_error "Falha ao desinstalar PostgreSQL Client"
        return 1
    }
    sudo apt-get autoremove -y
    return 0
}

# Uninstall PostgreSQL client on RedHat/CentOS/Fedora
uninstall_postgres_redhat() {
    local pkg_manager=$(get_redhat_pkg_manager)
    log_info "Desinstalando via $pkg_manager..."
    sudo $pkg_manager remove -y $POSTGRES_CLIENT_PKG_REDHAT || {
        log_error "Falha ao desinstalar PostgreSQL Client"
        return 1
    }
    return 0
}

# Uninstall PostgreSQL client on Arch Linux
uninstall_postgres_arch() {
    log_info "Desinstalando via pacman..."
    sudo pacman -R --noconfirm $POSTGRES_CLIENT_PKG_ARCH || {
        log_error "Falha ao desinstalar PostgreSQL Client"
        return 1
    }
    return 0
}
