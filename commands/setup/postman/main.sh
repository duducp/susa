#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"

# Help function
show_help() {
    show_description
    log_output ""
    show_usage
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Postman é uma plataforma completa para desenvolvimento de APIs."
    log_output "  Permite criar, testar, documentar e monitorar APIs de forma"
    log_output "  colaborativa. Suporta REST, SOAP, GraphQL e WebSocket."
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --uninstall       Desinstala o Postman do sistema"
    log_output "  -u, --upgrade     Atualiza o Postman para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup postman              # Instala o Postman"
    log_output "  susa setup postman --upgrade    # Atualiza o Postman"
    log_output "  susa setup postman --uninstall  # Desinstala o Postman"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  O Postman estará disponível no menu de aplicativos ou via:"
    log_output "    postman                 # Abre o Postman"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Construtor de requisições HTTP/HTTPS"
    log_output "  • Collections para organizar requests"
    log_output "  • Testes automatizados e scripts"
    log_output "  • Mock servers"
    log_output "  • Documentação automática de APIs"
    log_output "  • Monitoramento de APIs"
    log_output "  • Colaboração em equipe"
}

# Get installed Postman version
get_postman_version() {
    if command -v postman &> /dev/null; then
        # Postman não tem opção de versão via CLI, então verificamos se está instalado
        echo "instalada"
    else
        echo "desconhecida"
    fi
}

# Check if Postman is already installed
check_existing_installation() {
    if ! command -v postman &> /dev/null; then
        log_debug "Postman não está instalado"
        return 0
    fi

    local current_version=$(get_postman_version)
    log_info "Postman $current_version já está instalado."

    # Mark as installed in lock file
    mark_installed "postman" "$current_version"

    log_output ""
    log_output "${YELLOW}Para atualizar, execute:${NC} ${LIGHT_CYAN}susa setup postman --upgrade${NC}"

    return 1
}

# Install Postman on macOS using Homebrew
install_postman_macos() {
    log_info "Instalando Postman no macOS..."

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew não está instalado. Instale-o primeiro:"
        log_output "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi

    # Install or upgrade Postman
    log_debug "Executando: brew install --cask $POSTMAN_HOMEBREW_CASK"
    if brew list --cask "$POSTMAN_HOMEBREW_CASK" &> /dev/null; then
        log_info "Atualizando Postman via Homebrew..."
        brew upgrade --cask "$POSTMAN_HOMEBREW_CASK" || {
            log_warning "Postman já está na versão mais recente"
        }
    else
        log_info "Instalando Postman via Homebrew..."
        brew install --cask "$POSTMAN_HOMEBREW_CASK"
    fi

    log_success "Postman instalado com sucesso!"
    log_output ""
    log_output "${LIGHT_CYAN}Para abrir o Postman:${NC}"
    log_output "  • Via menu de aplicativos"
    log_output "  • Via terminal: ${LIGHT_GREEN}postman${NC}"
}

# Install Postman on Linux
install_postman_linux() {
    log_info "Instalando Postman no Linux..."

    # Create temporary directory
    local temp_dir=$(mktemp -d)
    local tarball="$temp_dir/postman.tar.gz"

    # Download Postman
    log_info "Baixando Postman..."
    log_debug "URL: $POSTMAN_DOWNLOAD_URL"
    if ! curl -L --progress-bar \
        --connect-timeout 30 \
        --max-time 300 \
        --retry 3 \
        --retry-delay 2 \
        "$POSTMAN_DOWNLOAD_URL" -o "$tarball"; then
        log_error "Falha ao baixar Postman"
        rm -rf "$temp_dir"
        return 1
    fi

    # Remove old installation if exists
    if [ -d "$POSTMAN_INSTALL_DIR" ]; then
        log_info "Removendo instalação anterior..."
        sudo rm -rf "$POSTMAN_INSTALL_DIR"
    fi

    # Extract to /opt
    log_info "Extraindo Postman..."
    sudo tar -xzf "$tarball" -C /opt

    # Create symbolic link
    log_info "Criando link simbólico..."
    sudo ln -sf "$POSTMAN_INSTALL_DIR/Postman" /usr/local/bin/postman

    # Create desktop entry
    log_info "Criando entrada no menu de aplicativos..."
    sudo tee "$POSTMAN_DESKTOP_FILE" > /dev/null << EOF
[Desktop Entry]
Name=Postman
GenericName=API Development Environment
Comment=Postman makes API development easy
Exec=$POSTMAN_INSTALL_DIR/Postman
Terminal=false
Type=Application
Icon=$POSTMAN_INSTALL_DIR/app/resources/app/assets/icon.png
Categories=Development;
EOF

    # Set permissions
    sudo chmod +x "$POSTMAN_DESKTOP_FILE"

    # Cleanup
    rm -rf "$temp_dir"

    log_success "Postman instalado com sucesso!"
    log_output ""
    log_output "${LIGHT_CYAN}Para abrir o Postman:${NC}"
    log_output "  • Via menu de aplicativos"
    log_output "  • Via terminal: ${LIGHT_GREEN}postman${NC}"
}

# Main installation function
install_postman() {
    local os_type=$(get_simple_os)

    if [ "$os_type" = "mac" ]; then
        install_postman_macos
    elif [ "$os_type" = "linux" ]; then
        install_postman_linux
    else
        log_error "Sistema operacional não suportado: $os_type"
        return 1
    fi

    # Mark as installed
    local version=$(get_postman_version)
    mark_installed "postman" "$version"
}

# Update Postman
update_postman() {
    log_info "Atualizando Postman..."

    if ! command -v postman &> /dev/null; then
        log_warning "Postman não está instalado. Execute sem --upgrade para instalar."
        return 1
    fi

    local current_version=$(get_postman_version)
    log_info "Versão atual: $current_version"

    local os_type=$(get_simple_os)

    if [ "$os_type" = "mac" ]; then
        log_info "Atualizando via Homebrew..."
        brew upgrade --cask "$POSTMAN_HOMEBREW_CASK" || {
            log_info "Postman já está na versão mais recente"
        }
    elif [ "$os_type" = "linux" ]; then
        log_info "Reinstalando Postman com a versão mais recente..."
        install_postman_linux
    fi

    local new_version=$(get_postman_version)
    log_success "Postman atualizado para versão $new_version"

    # Update lock file
    mark_installed "postman" "$new_version"
}

# Uninstall Postman
uninstall_postman() {
    log_info "Desinstalando Postman..."

    if ! command -v postman &> /dev/null; then
        log_warning "Postman não está instalado"
        return 0
    fi

    local os_type=$(get_simple_os)

    if [ "$os_type" = "mac" ]; then
        log_info "Desinstalando via Homebrew..."
        brew uninstall --cask "$POSTMAN_HOMEBREW_CASK"
    elif [ "$os_type" = "linux" ]; then
        log_info "Removendo arquivos do Postman..."
        sudo rm -rf "$POSTMAN_INSTALL_DIR"
        sudo rm -f /usr/local/bin/postman
        sudo rm -f "$POSTMAN_DESKTOP_FILE"
    fi

    log_success "Postman desinstalado com sucesso!"

    # Remove from lock file
    mark_uninstalled "postman"
}

# Main execution
main() {
    # Parse arguments
    local should_update=false
    local should_uninstall=false

    for arg in "$@"; do
        case "$arg" in
            -h | --help)
                show_help
                exit 0
                ;;
            -u | --upgrade)
                should_update=true
                ;;
            --uninstall)
                should_uninstall=true
                ;;
            -v | --verbose)
                # Verbose already handled by CLI framework
                ;;
            -q | --quiet)
                # Quiet already handled by CLI framework
                ;;
            *)
                log_error "Opção desconhecida: $arg"
                log_output "Use -h ou --help para ver as opções disponíveis"
                exit 1
                ;;
        esac
    done

    # Execute requested action
    if [ "$should_uninstall" = true ]; then
        uninstall_postman
    elif [ "$should_update" = true ]; then
        update_postman
    else
        # Check if already installed before attempting installation
        if check_existing_installation; then
            install_postman
        fi
    fi
}

# Run main function
main "$@"
