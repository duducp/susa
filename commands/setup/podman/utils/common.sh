#!/bin/bash
# Podman Common Utilities
# Shared functions used across install, update and uninstall

# Constants
PODMAN_NAME="Podman"
PODMAN_REPO="containers/podman"
PODMAN_BIN_NAME="podman"
PODMAN_COMPOSE_BIN="podman-compose"
PODMAN_HOMEBREW_PKG="podman"
PODMAN_HOMEBREW_COMPOSE_PKG="podman-compose"
PODMAN_HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
PODMAN_LINUX_FILENAME="podman-remote-static-linux_{arch}.tar.gz"
PODMAN_LINUX_BINARIES=("podman-remote-static" "podman-remote" "podman")
LOCAL_BIN_DIR="$HOME/.local/bin"

# Get latest version
get_latest_version() {
    github_get_latest_version "$PODMAN_REPO"
}

# Get installed Podman version
get_current_version() {
    if check_installation; then
        $PODMAN_BIN_NAME --version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Check if Podman is installed
check_installation() {
    command -v $PODMAN_BIN_NAME &> /dev/null
}

# Show additional Podman-specific information
show_additional_info() {
    if ! check_installation; then
        return
    fi

    # Check podman machine status (macOS)
    if is_mac && command -v podman &> /dev/null; then
        local machine_status=$(podman machine list --format "{{.Running}}" 2> /dev/null | head -1)
        if [ "$machine_status" = "true" ]; then
            log_output "  ${CYAN}Machine:${NC} ${GREEN}rodando${NC}"
        elif [ -n "$machine_status" ]; then
            log_output "  ${CYAN}Machine:${NC} parada"
        fi
    fi

    # Count containers
    if command -v podman &> /dev/null; then
        local total_containers=$(podman ps -a --format "{{.ID}}" 2> /dev/null | wc -l | xargs)
        local running_containers=$(podman ps --format "{{.ID}}" 2> /dev/null | wc -l | xargs)
        if [ "$total_containers" != "0" ] || [ "$running_containers" != "0" ]; then
            log_output "  ${CYAN}Containers:${NC} $total_containers total, $running_containers rodando"
        fi

        # Count images
        local images=$(podman images --format "{{.ID}}" 2> /dev/null | wc -l | xargs)
        if [ "$images" != "0" ]; then
            log_output "  ${CYAN}Imagens:${NC} $images"
        fi
    fi

    # Check podman-compose
    if command -v podman-compose &> /dev/null; then
        log_output "  ${CYAN}Compose:${NC} disponível"
    fi
}

# Install Podman on macOS using Homebrew
install_podman_macos() {
    log_info "Instalando Podman no macOS..."

    if ! homebrew_is_available; then
        log_error "Homebrew não está instalado. Instale-o primeiro:"
        log_output "  /bin/bash -c \"\$(curl -fsSL $PODMAN_HOMEBREW_INSTALL_URL)\""
        return 1
    fi

    # Install or upgrade Podman
    if homebrew_is_installed_formula "$PODMAN_HOMEBREW_PKG"; then
        log_info "Atualizando Podman via Homebrew..."
        homebrew_update_formula "$PODMAN_HOMEBREW_PKG" "Podman" || true
    else
        log_info "Instalando Podman via Homebrew..."
        homebrew_install_formula "$PODMAN_HOMEBREW_PKG" "Podman"
    fi

    # Install podman-compose if not present
    if ! homebrew_is_installed_formula "$PODMAN_HOMEBREW_COMPOSE_PKG"; then
        log_info "Instalando podman-compose..."
        homebrew_install_formula "$PODMAN_HOMEBREW_COMPOSE_PKG" "podman-compose" || log_debug "$PODMAN_COMPOSE_BIN não disponível via homebrew"
    fi

    # Initialize podman machine
    log_info "Inicializando máquina virtual do Podman..."
    podman machine init 2> /dev/null || log_debug "Máquina virtual já existe"
    podman machine start || log_debug "Máquina virtual já está rodando"

    return 0
}

# Try to install Podman via system package manager
install_podman_via_package_manager() {
    log_info "Tentando instalar Podman via gerenciador de pacotes..."

    local installed=false

    if command -v apt-get &> /dev/null; then
        log_debug "Instalando via apt-get..."
        if sudo apt-get update > /dev/null 2>&1 && sudo apt-get install -y podman; then
            installed=true
        fi
    elif command -v dnf &> /dev/null; then
        log_debug "Instalando via dnf..."
        if sudo dnf install -y podman; then
            installed=true
        fi
    elif command -v yum &> /dev/null; then
        log_debug "Instalando via yum..."
        if sudo yum install -y podman; then
            installed=true
        fi
    elif command -v pacman &> /dev/null; then
        log_debug "Instalando via pacman..."
        if sudo pacman -S --noconfirm podman; then
            installed=true
        fi
    fi

    if [ "$installed" = true ]; then
        log_success "Podman instalado via gerenciador de pacotes"
        return 0
    fi

    return 1
}

# Enable and start Podman socket for rootless mode
enable_podman_service() {
    log_info "Configurando serviço Podman para usuário..."

    # Enable user lingering (allows user services to run without login)
    if command -v loginctl &> /dev/null; then
        loginctl enable-linger "$USER" 2> /dev/null || log_debug "Linger já habilitado"
    fi

    # Enable and start Podman socket
    if command -v systemctl &> /dev/null; then
        systemctl --user enable podman.socket 2> /dev/null || log_debug "Socket já habilitado"
        systemctl --user start podman.socket 2> /dev/null || log_debug "Socket já iniciado"

        # Verify socket is running
        if systemctl --user is-active podman.socket > /dev/null 2>&1; then
            log_debug "Serviço Podman iniciado com sucesso"
            return 0
        else
            log_warning "Não foi possível iniciar o serviço Podman automaticamente"
            log_info "Execute manualmente: systemctl --user start podman.socket"
            return 1
        fi
    fi

    return 0
}

# Install Podman on Linux using package manager
install_podman_linux() {
    log_info "Instalando Podman no Linux..."

    # Try package manager first (recommended)
    if install_podman_via_package_manager; then
        # Enable and start Podman service
        enable_podman_service
        return 0
    fi

    log_warning "Instalação via gerenciador de pacotes falhou"
    log_info "Tentando instalação via binário estático..."

    # Get latest version
    local podman_version=$(get_latest_version)
    if [ $? -ne 0 ] || [ -z "$podman_version" ]; then
        return 1
    fi

    # Detect OS and architecture using github library
    local os_arch=$(github_detect_os_arch "standard")
    if [ $? -ne 0 ]; then
        return 1
    fi

    local arch="${os_arch#*:}"
    # Convert arch format for Podman (x64 -> amd64)
    case "$arch" in
        x64) arch="amd64" ;;
        arm64) arch="arm64" ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    local install_dir="$LOCAL_BIN_DIR"
    mkdir -p "$install_dir"

    # Build download URL with correct filename for checksum verification
    local filename="podman-remote-static-linux_${arch}.tar.gz"
    local download_url="https://github.com/$PODMAN_REPO/releases/download/${podman_version}/${filename}"
    local output_file="/tmp/${filename}"

    log_info "Baixando e verificando Podman ${podman_version}..."
    log_debug "URL: $download_url"

    # Download and verify with checksum
    if ! github_download_and_verify "$PODMAN_REPO" "$podman_version" "$download_url" "$output_file" "shasums" "sha256"; then
        log_error "Falha ao baixar ou verificar Podman"
        return 1
    fi

    # Extract binary
    log_info "Extraindo Podman..."
    local temp_dir="/tmp/podman-extract-$$"
    mkdir -p "$temp_dir"

    if ! tar -xzf "$output_file" -C "$temp_dir" 2> /dev/null; then
        log_error "Falha ao extrair Podman"
        rm -rf "$temp_dir" "$output_file"
        return 1
    fi
    rm -f "$output_file"

    # List extracted files for debugging
    log_debug "Arquivos extraídos:"
    find "$temp_dir" -type f | while read file; do
        log_debug "  $(basename "$file")"
    done

    # Find and install binary (try multiple possible names)
    local podman_binary=""
    for bin_name in "${PODMAN_LINUX_BINARIES[@]}"; do
        podman_binary=$(find "$temp_dir" -type f -name "$bin_name" | head -1)
        [ -n "$podman_binary" ] && break
    done
    if [ -z "$podman_binary" ]; then
        # Try to find any executable file
        log_debug "Procurando por executável..."
        podman_binary=$(find "$temp_dir" -type f -executable | head -1)
    fi
    if [ -z "$podman_binary" ]; then
        log_error "Binário do Podman não encontrado no arquivo"
        log_debug "Conteúdo do diretório:"
        ls -la "$temp_dir"
        rm -rf "$temp_dir"
        return 1
    fi
    log_debug "Binário encontrado: $podman_binary"
    local podman_bin="$LOCAL_BIN_DIR/$PODMAN_BIN_NAME"
    mv "$podman_binary" "$podman_bin"
    chmod +x "$podman_bin"
    rm -rf "$temp_dir"
    log_debug "Binário instalado em $podman_bin"

    # Configure PATH if needed
    local shell_config=$(detect_shell_config)
    if ! grep -q ".local/bin" "$shell_config" 2> /dev/null; then
        echo "" >> "$shell_config"
        echo "# Local binaries PATH" >> "$shell_config"
        echo "export PATH=\"$LOCAL_BIN_DIR:\$PATH\"" >> "$shell_config"
        log_debug "PATH configurado em $shell_config"
    fi

    # Update current session PATH
    export PATH="$LOCAL_BIN_DIR:$PATH"

    # Warning about static binary limitations
    log_warning "Binário estático instalado - algumas funcionalidades podem ser limitadas"
    log_info "Para melhor experiência, considere instalar via gerenciador de pacotes"
    log_info "Você precisará configurar o serviço Podman manualmente"

    # Install podman-compose
    log_info "Instalando podman-compose..."

    local compose_installed=false

    # Try to install via package manager first
    if command -v apt-get &> /dev/null; then
        if sudo apt-get install -y podman-compose > /dev/null 2>&1; then
            log_debug "podman-compose instalado via apt-get"
            compose_installed=true
        fi
    elif command -v dnf &> /dev/null; then
        if sudo dnf install -y podman-compose > /dev/null 2>&1; then
            log_debug "podman-compose instalado via dnf"
            compose_installed=true
        fi
    elif command -v yum &> /dev/null; then
        if sudo yum install -y podman-compose > /dev/null 2>&1; then
            log_debug "podman-compose instalado via yum"
            compose_installed=true
        fi
    fi

    # If package manager installation failed, try pip
    if [ "$compose_installed" = false ]; then
        log_debug "podman-compose não disponível via gerenciador de pacotes, tentando via pip..."

        # Ensure pip3 is installed
        ensure_pip3_installed || return 1

        pip3 install --user podman-compose > /dev/null 2>&1 || log_debug "Não foi possível instalar podman-compose"
    fi

    # Verify installation
    if ! command -v $PODMAN_BIN_NAME &> /dev/null; then
        log_error "Falha na instalação do Podman"
        return 1
    fi

    return 0
}

# Update Podman on macOS
update_podman_macos() {
    if ! homebrew_is_available; then
        log_error "Homebrew não está instalado"
        return 1
    fi

    log_info "Atualizando Podman via Homebrew..."
    homebrew_update_formula "$PODMAN_HOMEBREW_PKG" "Podman" || {
        log_error "Falha ao atualizar Podman"
        return 1
    }

    # Update podman-compose if installed
    if homebrew_is_installed_formula "$PODMAN_HOMEBREW_COMPOSE_PKG"; then
        log_info "Atualizando podman-compose..."
        homebrew_update_formula "$PODMAN_HOMEBREW_COMPOSE_PKG" "podman-compose" || log_debug "$PODMAN_COMPOSE_BIN já está atualizado"
    fi

    return 0
}

# Update Podman on Linux
update_podman_linux() {
    # Remove old binary
    local podman_bin="$LOCAL_BIN_DIR/podman"
    if [ -f "$podman_bin" ]; then
        log_info "Removendo versão anterior..."
        rm -f "$podman_bin"
    fi

    # Install new version
    install_podman_linux
    return $?
}

# Uninstall Podman on macOS
uninstall_podman_macos() {
    # Stop and remove podman machine
    if check_installation; then
        log_info "Parando máquina virtual do Podman..."
        podman machine stop 2> /dev/null || true
        podman machine rm -f 2> /dev/null || true
    fi

    # Uninstall via Homebrew
    if homebrew_is_available; then
        log_info "Removendo Podman via Homebrew..."
        homebrew_uninstall_formula "$PODMAN_HOMEBREW_PKG" "Podman" || log_debug "Podman não instalado via Homebrew"
        homebrew_uninstall_formula "$PODMAN_HOMEBREW_COMPOSE_PKG" "podman-compose" || log_debug "$PODMAN_COMPOSE_BIN não instalado"
    fi
}

# Uninstall Podman on Linux
uninstall_podman_linux() {
    local podman_location=$(which podman 2> /dev/null)
    local removed_system=false

    # Check if installed via system package manager
    if [ -n "$podman_location" ]; then
        log_debug "Podman encontrado em: $podman_location"

        # Detect installation method
        if [[ "$podman_location" == "/usr/bin/podman" ]] || [[ "$podman_location" == "/usr/local/bin/podman" ]]; then
            log_info "Detectado Podman instalado via gerenciador de pacotes do sistema"

            # Try to remove via package manager
            if command -v apt-get &> /dev/null; then
                log_debug "Verificando instalação via apt..."
                if dpkg -l podman 2> /dev/null | grep -q "^ii"; then
                    log_info "Removendo Podman via apt..."
                    log_debug "Executando: sudo apt-get remove -y podman"
                    local apt_output=$(sudo apt-get remove -y podman 2>&1)
                    local apt_exit=$?
                    echo "$apt_output" | while read -r line; do log_debug "apt: $line"; done
                    if [ $apt_exit -eq 0 ]; then
                        removed_system=true
                        log_debug "Podman removido via apt com sucesso"
                    else
                        log_warning "Falha ao remover Podman via apt (código $apt_exit)"
                    fi
                else
                    log_debug "Podman não está instalado via apt"
                fi
            elif command -v dnf &> /dev/null; then
                if rpm -qa | grep -q "^podman"; then
                    log_info "Removendo Podman via dnf..."
                    local dnf_output=$(sudo dnf remove -y podman 2>&1)
                    local dnf_exit=$?
                    echo "$dnf_output" | while read -r line; do log_debug "dnf: $line"; done
                    if [ $dnf_exit -eq 0 ]; then
                        removed_system=true
                        log_debug "Podman removido via dnf com sucesso"
                    else
                        log_warning "Falha ao remover Podman via dnf (código $dnf_exit)"
                    fi
                fi
            elif command -v yum &> /dev/null; then
                if rpm -qa | grep -q "^podman"; then
                    log_info "Removendo Podman via yum..."
                    local yum_output=$(sudo yum remove -y podman 2>&1)
                    local yum_exit=$?
                    echo "$yum_output" | while read -r line; do log_debug "yum: $line"; done
                    if [ $yum_exit -eq 0 ]; then
                        removed_system=true
                        log_debug "Podman removido via yum com sucesso"
                    else
                        log_warning "Falha ao remover Podman via yum (código $yum_exit)"
                    fi
                fi
            elif command -v pacman &> /dev/null; then
                if pacman -Q podman &> /dev/null; then
                    log_info "Removendo Podman via pacman..."
                    local pacman_output=$(sudo pacman -R --noconfirm podman 2>&1)
                    local pacman_exit=$?
                    echo "$pacman_output" | while read -r line; do log_debug "pacman: $line"; done
                    if [ $pacman_exit -eq 0 ]; then
                        removed_system=true
                        log_debug "Podman removido via pacman com sucesso"
                    else
                        log_warning "Falha ao remover Podman via pacman (código $pacman_exit)"
                    fi
                fi
            fi
        fi
    fi

    # Remove binary from local bin if exists
    local podman_bin="$LOCAL_BIN_DIR/$PODMAN_BIN_NAME"
    if [ -f "$podman_bin" ]; then
        rm -f "$podman_bin"
        log_debug "Binário local removido: $podman_bin"
    fi

    # Remove podman-compose
    log_info "Removendo $PODMAN_COMPOSE_BIN..."

    # Try to remove via package manager first
    if command -v apt-get &> /dev/null; then
        sudo apt-get remove -y $PODMAN_COMPOSE_BIN > /dev/null 2>&1 || log_debug "$PODMAN_COMPOSE_BIN não instalado via apt-get"
    elif command -v dnf &> /dev/null; then
        sudo dnf remove -y $PODMAN_COMPOSE_BIN > /dev/null 2>&1 || log_debug "$PODMAN_COMPOSE_BIN não instalado via dnf"
    elif command -v yum &> /dev/null; then
        sudo yum remove -y $PODMAN_COMPOSE_BIN > /dev/null 2>&1 || log_debug "$PODMAN_COMPOSE_BIN não instalado via yum"
    fi

    # Also try to remove from pip
    if command -v pip3 &> /dev/null; then
        pip3 uninstall -y $PODMAN_COMPOSE_BIN > /dev/null 2>&1 || log_debug "$PODMAN_COMPOSE_BIN não instalado via pip"
    fi
}

# Remove Podman data directories
remove_podman_data() {
    log_info "Removendo dados do Podman..."

    if [ -d "$HOME/.local/share/containers" ]; then
        rm -rf "$HOME/.local/share/containers" 2> /dev/null || true
        log_debug "Dados removidos: ~/.local/share/containers"
    fi

    if [ -d "$HOME/.config/containers" ]; then
        rm -rf "$HOME/.config/containers" 2> /dev/null || true
        log_debug "Configurações removidas: ~/.config/containers"
    fi

    if [ -d "$HOME/.cache/containers" ]; then
        rm -rf "$HOME/.cache/containers" 2> /dev/null || true
        log_debug "Cache removido: ~/.cache/containers"
    fi

    log_success "Dados do Podman removidos"
}
