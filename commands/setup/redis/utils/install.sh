#!/usr/bin/env zsh
# Redis CLI Installation Functions

# Install Redis CLI on macOS
install_redis_macos() {
    log_info "Instalando Redis CLI via Homebrew..."

    if ! homebrew_is_available; then
        log_error "Homebrew não está instalado. Instale primeiro com:"
        log_output "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi

    if ! homebrew_install_formula "$REDIS_PKG_MACOS" "Redis CLI"; then
        log_error "Falha ao instalar Redis CLI via Homebrew"
        return 1
    fi

    return 0
}

# Install Redis CLI on Debian/Ubuntu
install_redis_debian() {
    log_info "Instalando Redis CLI no Debian/Ubuntu..."

    if ! sudo apt-get update -qq; then
        log_error "Falha ao atualizar lista de pacotes"
        return 1
    fi

    if ! sudo apt-get install -y $REDIS_PKG_DEBIAN; then
        log_error "Falha ao instalar Redis CLI"
        return 1
    fi

    return 0
}

# Install Redis CLI on RedHat/CentOS/Fedora
install_redis_redhat() {
    log_info "Instalando Redis CLI no RedHat/CentOS/Fedora..."
    local pkg_manager=$(get_redhat_pkg_manager)

    if ! sudo $pkg_manager install -y $REDIS_PKG_REDHAT; then
        log_error "Falha ao instalar Redis CLI"
        return 1
    fi

    return 0
}

# Install Redis CLI on Arch Linux
install_redis_arch() {
    log_info "Instalando Redis CLI no Arch Linux..."

    if ! sudo pacman -S --noconfirm $REDIS_PKG_ARCH; then
        log_error "Falha ao instalar Redis CLI"
        return 1
    fi

    return 0
}
