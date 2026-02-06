#!/usr/bin/env zsh
# PostgreSQL Client Update Functions

# Update PostgreSQL client on macOS using Homebrew
update_postgres_macos() {
    log_info "Atualizando via Homebrew..."
    if homebrew_is_available; then
        if homebrew_update_formula "$POSTGRES_CLIENT_PKG_HOMEBREW" "PostgreSQL Client"; then
            return 0
        else
            log_info "PostgreSQL Client já está na versão mais recente"
            return 0
        fi
    else
        log_error "Homebrew não está disponível"
        return 1
    fi
}

# Update PostgreSQL client on Debian/Ubuntu
update_postgres_debian() {
    log_info "Atualizando via apt..."
    sudo apt-get update -qq
    sudo apt-get install --only-upgrade -y $POSTGRES_CLIENT_PKG_DEBIAN || {
        log_info "PostgreSQL Client já está na versão mais recente"
    }
    return 0
}

# Update PostgreSQL client on RedHat/CentOS/Fedora
update_postgres_redhat() {
    local pkg_manager=$(get_redhat_pkg_manager)
    log_info "Atualizando via $pkg_manager..."
    sudo $pkg_manager upgrade -y $POSTGRES_CLIENT_PKG_REDHAT || {
        log_info "PostgreSQL Client já está na versão mais recente"
    }
    return 0
}

# Update PostgreSQL client on Arch Linux
update_postgres_arch() {
    log_info "Atualizando via pacman..."
    sudo pacman -Syu --noconfirm $POSTGRES_CLIENT_PKG_ARCH || {
        log_info "PostgreSQL Client já está na versão mais recente"
    }
    return 0
}
