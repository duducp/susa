#!/bin/bash
# MySQL Client Installation Functions

# Install MySQL client on macOS using Homebrew
install_mysql_macos() {
    log_info "Instalando MySQL Client via Homebrew..."
    if ! homebrew_is_available; then
        log_error "Homebrew não está instalado. Instale primeiro com:"
        log_output "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi

    log_debug "Obtendo versão mais recente do MySQL Client para macOS..."
    local major_version=$(get_latest_version)
    log_debug "Versão mais recente para macOS: $major_version"

    if homebrew_is_installed_formula "$MYSQL_CLIENT_PKG_HOMEBREW"; then
        log_info "Atualizando MySQL Client via Homebrew..."
        homebrew_update_formula "$MYSQL_CLIENT_PKG_HOMEBREW" "MySQL Client" || true
    else
        log_info "Instalando $MYSQL_CLIENT_PKG_HOMEBREW via Homebrew..."
        homebrew_install_formula "$MYSQL_CLIENT_PKG_HOMEBREW" "MySQL Client" || return 1
    fi

    if ! command -v ${MYSQL_UTILS[0]} &> /dev/null; then
        log_info "Configurando binários no PATH..."
        log_debug "Executando: brew link --force $MYSQL_CLIENT_PKG_HOMEBREW"
        if ! brew link --force "$MYSQL_CLIENT_PKG_HOMEBREW" 2>&1 | while read -r line; do log_debug "brew: $line"; done; then
            log_warning "Não foi possível criar links automaticamente"
            log_output "Adicione manualmente ao seu PATH:"
            log_output "  export PATH=\"$MYSQL_HOMEBREW_PATH:\$PATH\""
        fi
    fi

    return 0
}

# Install MySQL client on Debian/Ubuntu
install_mysql_debian() {
    log_info "Instalando MySQL Client no Debian/Ubuntu..."
    log_debug "Atualizando lista de pacotes (apt)..."
    sudo apt-get update -qq || {
        log_error "Falha ao atualizar lista de pacotes"
        return 1
    }

    log_debug "Instalando mysql-client via apt..."
    log_info "Instalando mysql-client..."
    sudo apt-get install -y $MYSQL_CLIENT_PKG_DEBIAN || {
        log_error "Falha ao instalar MySQL Client"
        return 1
    }

    log_debug "Instalação via apt finalizada."
    return 0
}

# Install MySQL client on RedHat/CentOS/Fedora
install_mysql_redhat() {
    log_info "Instalando MySQL Client no RedHat/CentOS/Fedora..."
    local pkg_manager=$(get_redhat_pkg_manager)

    log_debug "Instalando mysql via $pkg_manager..."
    log_info "Instalando mysql via $pkg_manager..."
    sudo $pkg_manager install -y $MYSQL_CLIENT_PKG_REDHAT || {
        log_error "Falha ao instalar MySQL Client"
        return 1
    }

    log_debug "Instalação via $pkg_manager finalizada."
    return 0
}

# Install MySQL client on Arch Linux
install_mysql_arch() {
    log_info "Instalando MySQL Client no Arch Linux..."
    log_debug "Instalando mysql-clients via pacman..."
    log_info "Instalando mysql-clients via pacman..."
    sudo pacman -S --noconfirm $MYSQL_CLIENT_PKG_ARCH || {
        log_error "Falha ao instalar MySQL Client"
        return 1
    }

    log_debug "Instalação via pacman finalizada."
    return 0
}
