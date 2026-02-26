#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

UTILS_DIR="$(dirname "$0")/../utils"

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/homebrew.sh"
source "$UTILS_DIR/common.sh"

# Update on macOS
update_macos() {
    if homebrew_is_installed "$HOMEBREW_PACKAGE"; then
        homebrew_update "$HOMEBREW_PACKAGE" "$SOFTWARE_NAME"
    else
        log_error "$SOFTWARE_NAME não está instalado via Homebrew"
        return 1
    fi
}

# Update on Linux
update_linux() {
    log_info "Obtendo informações da versão mais recente..."

    local latest_version=$(get_latest_version)

    if [ "$latest_version" = "unknown" ] || [ -z "$latest_version" ]; then
        log_warning "Não foi possível obter a versão mais recente"
        log_info "Prosseguindo com atualização da versão mais recente disponível..."
        latest_version="latest"
    else
        log_info "Versão disponível: $latest_version"
    fi

    # Detectar arquitetura
    local arch=$(uname -m)
    local download_arch=""

    case "$arch" in
        x86_64)
            download_arch="x64"
            ;;
        aarch64 | arm64)
            download_arch="arm64"
            ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    log_debug "Arquitetura detectada: $download_arch"

    # Detectar tipo de pacote
    local package_type=""
    local package_ext=""

    if is_linux_debian; then
        package_type="deb"
        package_ext=".deb"
        log_debug "Sistema baseado em Debian/Ubuntu detectado"
    elif is_linux_redhat; then
        package_type="rpm"
        package_ext=".rpm"
        log_debug "Sistema baseado em RedHat/Fedora detectado"
    else
        package_type=""
        package_ext=".tar.gz"
        log_debug "Usando pacote genérico tar.gz"
    fi

    # Construir URL de download
    local download_url="${CURSOR_BASE_URL}/linux-${download_arch}${package_type:+-$package_type}/cursor/${latest_version}"
    local temp_file="/tmp/cursor${package_ext}"

    log_debug "URL de download: $download_url"
    log_debug "Arquivo temporário: $temp_file"

    # Download
    log_info "Baixando última versão..."
    if ! curl -fsSL "$download_url" -o "$temp_file"; then
        log_error "Falha ao baixar $SOFTWARE_NAME"
        log_output "URL: $download_url"
        return 1
    fi

    # Instalar/Atualizar baseado no tipo de pacote
    log_info "Atualizando $SOFTWARE_NAME..."

    if [ "$package_type" = "deb" ]; then
        # Atualizar .deb com dpkg
        if ! sudo dpkg -i "$temp_file" 2>&1 | grep -v "warning"; then
            log_warning "Corrigindo dependências..."
            sudo apt-get install -f -y
        fi
        rm -f "$temp_file"

    elif [ "$package_type" = "rpm" ]; then
        # Atualizar .rpm com dnf/yum
        local pkg_manager=$(get_redhat_pkg_manager)
        if ! sudo "$pkg_manager" install -y "$temp_file"; then
            log_error "Falha ao atualizar pacote RPM"
            rm -f "$temp_file"
            return 1
        fi
        rm -f "$temp_file"

    else
        # Atualizar tar.gz extraído
        local install_dir="$HOME/.local/cursor"

        # Fazer backup da versão atual
        if [ -d "$install_dir" ]; then
            log_debug "Fazendo backup da versão atual..."
            mv "$install_dir" "${install_dir}.backup"
        fi

        mkdir -p "$install_dir"

        if ! tar -xzf "$temp_file" -C "$install_dir" --strip-components=1; then
            log_error "Falha ao extrair $SOFTWARE_NAME"

            # Restaurar backup
            if [ -d "${install_dir}.backup" ]; then
                log_info "Restaurando versão anterior..."
                rm -rf "$install_dir"
                mv "${install_dir}.backup" "$install_dir"
            fi

            rm -f "$temp_file"
            return 1
        fi

        # Remover backup se sucesso
        rm -rf "${install_dir}.backup"
        rm -f "$temp_file"

        # Garantir que o symlink existe
        local bin_dir="$HOME/.local/bin"
        mkdir -p "$bin_dir"
        ln -sf "$install_dir/cursor" "$bin_dir/cursor"
    fi

    log_success "$SOFTWARE_NAME atualizado com sucesso!"
    return 0
}

# Main function
main() {
    log_info "Atualizando $SOFTWARE_NAME..."

    if ! check_installation; then
        log_error "$SOFTWARE_NAME não está instalado."
        log_output "Use ${LIGHT_CYAN}susa setup cursor install${NC} para instalar"
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"

    if is_mac; then
        update_macos
    else
        update_linux
    fi

    local update_result=$?

    if [ $update_result -eq 0 ]; then
        local new_version=$(get_current_version)
        register_or_update_software_in_lock "cursor" "$new_version"

        if [ "$current_version" = "$new_version" ]; then
            log_info "$SOFTWARE_NAME já estava na versão mais recente ($current_version)"
        else
            log_success "$SOFTWARE_NAME atualizado de $current_version para $new_version"
        fi
    fi

    return $update_result
}

# Execute main only if not showing help
[ "${SUSA_SHOW_HELP:-}" != "1" ] && main "$@"
