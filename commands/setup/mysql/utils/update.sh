#!/usr/bin/env zsh
# MySQL Client Update Functions

# Update MySQL client on macOS using Homebrew
update_mysql_macos() {
    log_info "Atualizando via Homebrew..."
    if homebrew_is_available; then
        if homebrew_update_formula "$MYSQL_CLIENT_PKG_HOMEBREW" "MySQL Client"; then
            return 0
        else
            log_info "MySQL Client já está na versão mais recente"
            return 0
        fi
    else
        log_error "Homebrew não está disponível"
        return 1
    fi
}

# Update MySQL client on Debian/Ubuntu
update_mysql_debian() {
    log_info "Atualizando via apt..."
    sudo apt-get update -qq
    sudo apt-get install --only-upgrade -y $MYSQL_CLIENT_PKG_DEBIAN || {
        log_info "MySQL Client já está na versão mais recente"
    }
    return 0
}

# Update MySQL client on RedHat/CentOS/Fedora
update_mysql_redhat() {
    local pkg_manager=$(get_redhat_pkg_manager)
    log_info "Atualizando via $pkg_manager..."
    sudo $pkg_manager upgrade -y $MYSQL_CLIENT_PKG_REDHAT || {
        log_info "MySQL Client já está na versão mais recente"
    }
    return 0
}

# Update MySQL client on Arch Linux
update_mysql_arch() {
    log_info "Atualizando via pacman..."
    sudo pacman -Syu --noconfirm $MYSQL_CLIENT_PKG_ARCH || {
        log_info "MySQL Client já está na versão mais recente"
    }
    return 0
}
