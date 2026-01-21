#!/bin/bash
# PostgreSQL Client Installation Functions

# Install PostgreSQL client on macOS using Homebrew
install_postgres_macos() {
    log_info "Instalando PostgreSQL Client via Homebrew..."
    if ! homebrew_is_available; then
        log_error "Homebrew não está instalado. Instale primeiro com:"
        log_output "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi

    log_debug "Obtendo versão mais recente do PostgreSQL Client para macOS..."
    local major_version=$(get_latest_version)
    log_debug "Versão mais recente para macOS: $major_version"

    if homebrew_is_installed_formula "$POSTGRES_CLIENT_PKG_HOMEBREW"; then
        log_info "Atualizando PostgreSQL Client via Homebrew..."
        homebrew_update_formula "$POSTGRES_CLIENT_PKG_HOMEBREW" "PostgreSQL Client" || true
    else
        log_info "Instalando $POSTGRES_CLIENT_PKG_HOMEBREW (PostgreSQL Client) via Homebrew..."
        homebrew_install_formula "$POSTGRES_CLIENT_PKG_HOMEBREW" "PostgreSQL Client" || return 1
    fi

    if ! command -v ${POSTGRES_UTILS[0]} &> /dev/null; then
        log_info "Configurando binários no PATH..."
        if ! homebrew_link_formula "$POSTGRES_CLIENT_PKG_HOMEBREW" "true"; then
            log_warning "Não foi possível criar links automaticamente"
            log_output "Adicione manualmente ao seu PATH:"
            log_output "  export PATH=\"$POSTGRES_HOMEBREW_PATH:\$PATH\""
        fi
    fi

    return 0
}

# Install PostgreSQL client on Debian/Ubuntu
install_postgres_debian() {
    log_info "Instalando PostgreSQL Client no Debian/Ubuntu..."
    log_debug "Atualizando lista de pacotes (apt)..."
    sudo apt-get update -qq || {
        log_error "Falha ao atualizar lista de pacotes"
        return 1
    }

    log_debug "Instalando postgresql-client via apt..."
    log_info "Instalando postgresql-client..."
    sudo apt-get install -y $POSTGRES_CLIENT_PKG_DEBIAN || {
        log_error "Falha ao instalar PostgreSQL Client"
        return 1
    }

    log_debug "Instalação via apt finalizada."
    return 0
}

# Install PostgreSQL client on RedHat/CentOS/Fedora
install_postgres_redhat() {
    log_info "Instalando PostgreSQL Client no RedHat/CentOS/Fedora..."
    local pkg_manager=$(get_redhat_pkg_manager)

    log_debug "Instalando postgresql via $pkg_manager..."
    log_info "Instalando postgresql via $pkg_manager..."
    sudo $pkg_manager install -y $POSTGRES_CLIENT_PKG_REDHAT || {
        log_error "Falha ao instalar PostgreSQL Client"
        return 1
    }

    log_debug "Instalação via $pkg_manager finalizada."
    return 0
}

# Install PostgreSQL client on Arch Linux
install_postgres_arch() {
    log_info "Instalando PostgreSQL Client no Arch Linux..."
    log_debug "Instalando postgresql-libs via pacman..."
    log_info "Instalando postgresql-libs via pacman..."
    sudo pacman -S --noconfirm $POSTGRES_CLIENT_PKG_ARCH || {
        log_error "Falha ao instalar PostgreSQL Client"
        return 1
    }

    log_debug "Instalação via pacman finalizada."
    return 0
}
